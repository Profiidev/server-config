resource "kubernetes_namespace" "kubevirt" {
  metadata {
    name = var.kubevirt_ns
  }
}

resource "helm_release" "kubevirt-crd" {
  name       = "kubevirt-crd"
  repository = "https://profiidev.github.io/helm-charts"
  chart      = "kubevirt-crd"
  version    = "1.8.2"
  namespace  = var.kubevirt_ns

  depends_on = [kubernetes_namespace.kubevirt]
}

resource "helm_release" "kubevirt" {
  name       = "kubevirt"
  repository = "https://profiidev.github.io/helm-charts"
  chart      = "kubevirt"
  version    = "1.8.3"
  namespace  = var.kubevirt_ns

  values = [templatefile("${path.module}/templates/kubevirt.values.tftpl", {
  })]

  depends_on = [kubernetes_namespace.kubevirt, helm_release.kubevirt-crd]
}

module "k8s_api_np_kubevirt" {
  source = "../modules/k8s-api-np"

  namespace = var.kubevirt_ns
  k8s_api   = var.k8s_api
}

resource "helm_release" "cdi-crd" {
  name       = "cdi-crd"
  repository = "https://profiidev.github.io/helm-charts"
  chart      = "cdi-crd"
  version    = "0.1.0"
  namespace  = var.kubevirt_ns

  depends_on = [kubernetes_namespace.kubevirt]
}

resource "helm_release" "cdi" {
  name       = "cdi"
  repository = "https://profiidev.github.io/helm-charts"
  chart      = "cdi"
  version    = "0.1.0"
  namespace  = var.kubevirt_ns

  values = [templatefile("${path.module}/templates/cdi.values.tftpl", {
  })]

  depends_on = [kubernetes_namespace.kubevirt, helm_release.cdi-crd]
}

resource "kubectl_manifest" "forgejo_image" {
  yaml_body = <<YAML
apiVersion: batch/v1
kind: CronJob
metadata:
  name: forgejo-nixos-builder
  namespace: ${var.kubevirt_ns}
spec:
  schedule: "0 0 31 2 *" # never
  concurrencyPolicy: Forbid
  jobTemplate:
    spec:
      template:
        spec:
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
                virtctl image-upload dv nixos-forgejo --size=2Gi --image-path=main.qcow2 --access-mode=ReadWriteOnce -n ${var.kubevirt_ns}
            securityContext:
              privileged: true
  YAML

  depends_on = [helm_release.cdi]
}

resource "kubectl_manifest" "forgejo_runner_secret" {
  yaml_body = <<YAML
apiVersion: external-secrets.io/v1
kind: ExternalSecret
metadata:
  name: forgejo-runner-secret
  namespace: ${var.kubevirt_ns}
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

  depends_on = [kubernetes_namespace.kubevirt]
}

resource "kubectl_manifest" "forgejo_runner" {
  yaml_body = <<YAML
apiVersion: kubevirt.io/v1
kind: VirtualMachine
metadata:
  name: forgejo-runner
  namespace: ${var.kubevirt_ns}
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
        resources:
          requests:
            memory: 4Gi
            cpu: "2"
      volumes:
        - name: rootdisk
          dataVolume:
            name: nixos-forgejo
        - name: forgejo-secret
          secret:
            secretName: forgejo-runner-secret
  YAML

  depends_on = [kubernetes_namespace.kubevirt, helm_release.kubevirt, kubectl_manifest.forgejo_runner_secret, kubectl_manifest.forgejo_image]
}

resource "kubectl_manifest" "kubevirt_egress" {
  yaml_body = <<YAML
apiVersion: crd.projectcalico.org/v1
kind: NetworkPolicy
metadata:
  name: kubevirt
  namespace: ${var.kubevirt_ns}
spec:
  order: 10
  namespaceSelector: kubernetes.io/metadata.name == '${var.kubevirt_ns}'
  types:
    - Egress
    - Ingress
  egress:
    - action: Allow
  ingress:
    - action: Allow
  YAML

  depends_on = [kubernetes_namespace.kubevirt]
}
