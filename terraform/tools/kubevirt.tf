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
  kind: Job
  metadata:
    name: forgejo-nixos-builder
    namespace: ${var.kubevirt_ns}
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
                # Enable flakes
                mkdir -p ~/.config/nix
                echo "experimental-features = nix-command flakes" > ~/.config/nix/nix.conf

                nix-env -iA nixpkgs.git nixpkgs.just nixpkgs.kubevirt
                git clone --depth 1 --branch main https://github.com/ProfiiDev/server-config.git
                cd server-config

                just forgejo-image
                virtctl image-upload dv nixos-forgejo --size=2Gi --image-path=main.qcow2 --access-mode=ReadWriteOnce -n ${var.kubevirt_ns}
  YAML

  depends_on = [helm_release.cdi]
}

resource "null_resource" "nixos-forgejo-image-build" {
  provisioner "local-exec" {
    command = "just forgejo-image"
  }
}

resource "null_resource" "nixos-forgejo-image-upload" {
  provisioner "local-exec" {
    command = "just forgejo-image-upload"
  }

  depends_on = [null_resource.nixos-forgejo-image-build, helm_release.cdi]
}

resource "kubectl_manifest" "test_vm" {
  yaml_body = <<YAML
apiVersion: kubevirt.io/v1
kind: VirtualMachine
metadata:
  name: example-vm
  namespace: ${var.kubevirt_ns}
spec:
  running: false # The VM won't start immediately upon creation
  template:
    metadata:
      labels:
        kubevirt.io/domain: example-vm
    spec:
      domain:
        devices:
          disks:
            - name: rootdisk
              disk: {bus: virtio}
        resources:
          requests:
            memory: 4Gi
            cpu: "2"
      volumes:
        - name: rootdisk
          dataVolume:
            name: nixos-forgejo
  YAML

  depends_on = [kubernetes_namespace.kubevirt, helm_release.kubevirt]
}
