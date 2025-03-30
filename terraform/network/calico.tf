resource "kubernetes_namespace" "calico" {
  metadata {
    name = var.calico
  }
}

resource "helm_release" "calico" {
  name       = "calico"
  repository = "https://docs.tigera.io/calico/charts"
  chart      = "tigera-operator"
  version    = "3.29.3"
  namespace  = var.calico

  depends_on = [kubernetes_namespace.calico]
}
