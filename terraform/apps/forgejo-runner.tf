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
  yaml_body = <<YAML
apiVersion: external-secrets.io/v1
kind: ExternalSecret
metadata:
  name: forgejo-runner-secret
  namespace: ${var.forgejo_ns}
spec:
  refreshInterval: 5m
  secretStoreRef:
    name: ${var.cluster_secret_store}
    kind: ClusterSecretStore
  target:
    name: forgejo-runner-secret
  dataFrom:
  - extract:
      key: tools/forgejo-runner
  YAML

  depends_on = [kubernetes_namespace.forgejo]
}

resource "kubernetes_persistent_volume_claim" "forgejo_docker_storage" {
  metadata {
    name      = "forgejo-docker-storage"
    namespace = var.forgejo_ns
  }
  spec {
    access_modes = ["ReadWriteOnce"]
    resources {
      requests = {
        storage = "20Gi"
      }
    }
  }

  depends_on = [kubernetes_namespace.forgejo]
}

resource "kubectl_manifest" "forgejo_runner" {
  yaml_body = <<YAML
apiVersion: kubevirt.io/v1
kind: VirtualMachine
metadata:
  name: forgejo-runner
  namespace: ${var.forgejo_ns}
spec:
  running: true
  template:
    metadata:
      labels:
        kubevirt.io/domain: forgejo-runner
    spec:
      domain:
        devices:
          disks:
            - name: rootdisk
              disk:
                bus: virtio
          filesystems:
            - name: forgejo-secret
              virtiofs: {}
            - name: docker-storage
              virtiofs: {}
          interfaces:
            - name: default
              masquerade: {}
        resources:
          requests:
            memory: 4Gi
            cpu: "2"
      volumes:
        - name: rootdisk
          dataVolume:
            name: nixos-forgejo
        - name: docker-storage
          persistentVolumeClaim:
            claimName: forgejo-docker-storage
        - name: forgejo-secret
          secret:
            secretName: forgejo-runner-secret
      networks:
        - name: default
          pod: {}
  YAML

  depends_on = [kubernetes_namespace.forgejo, kubectl_manifest.forgejo_runner_secret, kubectl_manifest.forgejo_image, kubernetes_persistent_volume_claim.forgejo_docker_storage, kubernetes_namespace.forgejo]
}
