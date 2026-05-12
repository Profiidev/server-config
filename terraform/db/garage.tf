resource "kubernetes_namespace" "garage" {
  metadata {
    name = var.garage_ns
  }
}

resource "helm_release" "garage" {
  name       = "garage"
  repository = "https://profiidev.github.io/helm-charts"
  chart      = "garage"
  version    = "0.9.3"
  namespace  = kubernetes_namespace.garage.metadata[0].name

  values = [templatefile("${path.module}/templates/garage.values.tftpl", {
  })]
}
