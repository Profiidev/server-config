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

resource "kubectl_manifest" "test_vm" {
  yaml_body = <<YAML
apiVersion: kubevirt.io/v1
kind: VirtualMachine
metadata:
  name: example-vm
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
            - name: containerdisk
              disk: {bus: virtio}
            - name: cloudinitdisk
              disk: {bus: virtio}
        resources:
          requests:
            memory: 1024Mi
      volumes:
        - name: containerdisk
          containerDisk:
            image: quay.io/containerdisks/ubuntu:22.04
        - name: cloudinitdisk
          cloudInitNoCloud:
            userData: |
              #cloud-config
              password: fedora
              user: fedora
              chpasswd: { expire: False }
  YAML

  depends_on = [kubernetes_namespace.kubevirt, helm_release.kubevirt]
}
