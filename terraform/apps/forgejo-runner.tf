resource "kubectl_manifest" "builder_sa" {
  yaml_body = <<YAML
apiVersion: v1
kind: ServiceAccount
metadata:
  name: forgejo-builder-sa
  namespace: ${var.forgejo_ns}
  YAML

  depends_on = [kubernetes_namespace.forgejo]
}

resource "kubectl_manifest" "builder_role" {
  yaml_body = <<YAML
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: forgejo-builder-role
rules:
  - apiGroups: [""]
    resources: ["persistentvolumeclaims", "events"]
    verbs: ["get", "list", "watch", "create", "delete"]
  - apiGroups: ["upload.cdi.kubevirt.io"]
    resources: ["uploadtokenrequests"]
    verbs: ["get", "list", "watch", "create", "delete"]
  - apiGroups: ["cdi.kubevirt.io"]
    resources: ["datavolumes"]
    verbs: ["get", "list", "watch", "create", "delete"]
  YAML

  depends_on = [kubectl_manifest.builder_sa]
}

resource "kubectl_manifest" "builder_role_binding" {
  yaml_body = <<YAML
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: forgejo-builder-binding
subjects:
  - kind: ServiceAccount
    name: forgejo-builder-sa
    namespace: ${var.forgejo_ns}
roleRef:
  kind: ClusterRole
  name: forgejo-builder-role
  apiGroup: rbac.authorization.k8s.io
YAML

  depends_on = [kubectl_manifest.builder_role]
}

resource "kubectl_manifest" "forgejo_image" {
  yaml_body = <<YAML
apiVersion: batch/v1
kind: CronJob
metadata:
  name: forgejo-nixos-builder
  namespace: ${var.forgejo_ns}
spec:
  schedule: "0 0 31 2 *" # never
  concurrencyPolicy: Forbid
  jobTemplate:
    spec:
      template:
        spec:
          serviceAccountName: forgejo-builder-sa
          restartPolicy: Never
          containers:
          - name: builder
            image: nixos/nix:latest
            command: ["/bin/sh", "-c"]
            args:
              - |
                set -euo pipefail

                mkdir -p /etc/nix && echo "experimental-features = nix-command flakes" >> /etc/nix/nix.conf
                echo "extra-substituters = https://nix-community.cachix.org" >> /etc/nix/nix.conf
                echo "extra-trusted-public-keys = nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs=" >> /etc/nix/nix.conf

                nix-env -iA nixpkgs.just nixpkgs.kubevirt nixpkgs.qemu-utils
                git clone --depth 1 --branch main https://github.com/ProfiiDev/server-config.git
                cd server-config

                just forgejo-image
                virtctl image-upload dv nixos-forgejo --size=3Gi --image-path=main.qcow2 --access-mode=ReadWriteOnce -n ${var.forgejo_ns} --uploadproxy-url https://cdi-uploadproxy.${var.kubevirt_ns}.svc --insecure
            securityContext:
              privileged: true
  YAML

  depends_on = [kubectl_manifest.builder_role_binding]
}

resource "null_resource" "forgejo_image_build_trigger" {
  provisioner "local-exec" {
    command = "kubectl create job forgejo-image-build-trigger -n ${var.forgejo_ns} --from=cronjob/forgejo-nixos-builder"
  }

  depends_on = [kubectl_manifest.forgejo_image]
}

resource "kubectl_manifest" "forgejo_runner_secret" {
  for_each = { for vm in ["node1", "node2", "node3"] : vm => vm }

  yaml_body = <<YAML
apiVersion: external-secrets.io/v1
kind: ExternalSecret
metadata:
  name: forgejo-runner-secret-${each.key}
  namespace: ${var.forgejo_ns}
spec:
  refreshInterval: 5m
  secretStoreRef:
    name: ${var.cluster_secret_store}
    kind: ClusterSecretStore
  target:
    name: forgejo-runner-secret-${each.key}
    template:
      engineVersion: v2
      data:
        "runner-config.yaml": |
          server:
            connections:
              forgejo:
                url: https://git.profidev.io/
                token: {{ index . "${each.key}-token" }}
                uuid: {{ index . "${each.key}-uuid" }}
          runner:
            name: ${each.key}
            capacity: 10
            labels:
              - nixos-latest:docker://nixos/nix
              - ubuntu-latest:docker://catthehacker/ubuntu:act-latest
              - rust-latest:docker://catthehacker/ubuntu:rust-latest
              - node-latest:docker://catthehacker/ubuntu:js-latest
              - gh-latest:docker://catthehacker/ubuntu:gh-latest
          cache:
            enabled: true
            secret: {{ index . "CACHE_SECRET" }}
            external_server: "http://forgejo-runner-cache.forgejo.svc.cluster.local:8000"
  dataFrom:
  - extract:
      key: tools/forgejo-runner
  YAML

  depends_on = [kubernetes_namespace.forgejo]
}

resource "kubernetes_persistent_volume_claim" "forgejo_runner_storage" {
  for_each = { for vm in ["node1", "node2", "node3"] : vm => vm }

  metadata {
    name      = "forgejo-runner-storage-${each.key}"
    namespace = var.forgejo_ns
  }
  spec {
    access_modes = ["ReadWriteOnce"]
    resources {
      requests = {
        storage = "30Gi"
      }
    }
  }

  depends_on = [kubernetes_namespace.forgejo]
}

resource "kubectl_manifest" "forgejo_runner" {
  for_each = { for vm in ["node1", "node2", "node3"] : vm => vm }

  yaml_body = <<YAML
apiVersion: kubevirt.io/v1
kind: VirtualMachine
metadata:
  name: forgejo-runner-${each.key}
  namespace: ${var.forgejo_ns}
spec:
  running: true
  dataVolumeTemplates:
    - metadata:
        name: nixos-forgejo-${each.key}
      spec:
        source:
          pvc:
            namespace: ${var.forgejo_ns}
            name: nixos-forgejo
        storage:
          resources:
            requests:
              storage: 3Gi
  template:
    metadata:
      labels:
        kubevirt.io/domain: forgejo-runner
    spec:
      nodeSelector:
        "kubernetes.io/hostname": "${each.key}"
      domain:
        devices:
          disks:
            - name: rootdisk
              disk:
                bus: virtio
            - name: runner-storage
              disk:
                bus: virtio
          filesystems:
            - name: forgejo-secret
              virtiofs: {}
          interfaces:
            - name: default
              masquerade: {}
        resources:
          limits:
            memory: 6Gi
            cpu: "6"
          requests:
            memory: 1Gi
            cpu: "1"
        memory:
          guest: 6Gi
      volumes:
        - name: rootdisk
          dataVolume:
            name: nixos-forgejo-${each.key}
        - name: runner-storage
          persistentVolumeClaim:
            claimName: forgejo-runner-storage-${each.key}
        - name: forgejo-secret
          secret:
            secretName: forgejo-runner-secret-${each.key}
      networks:
        - name: default
          pod: {}
  YAML

  depends_on = [kubernetes_namespace.forgejo, kubectl_manifest.forgejo_runner_secret, kubectl_manifest.forgejo_image, kubernetes_namespace.forgejo, kubernetes_persistent_volume_claim.forgejo_runner_storage]
}
