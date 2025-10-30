resource "kubernetes_namespace" "nats" {
  metadata {
    name = var.nats_ns
  }
}

resource "helm_release" "nats" {
  name       = "nats"
  repository = "https://nats-io.github.io/k8s/helm/charts"
  chart      = "nats"
  version    = "2.12.1"
  namespace  = var.nats_ns

  values = [templatefile("${path.module}/templates/nats.values.tftpl", {
  })]

  depends_on = [kubernetes_namespace.nats]
}
