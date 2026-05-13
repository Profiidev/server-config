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
