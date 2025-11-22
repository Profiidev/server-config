resource "helm_release" "loki" {
  name       = "loki"
  repository = "https://grafana.github.io/helm-charts"
  chart      = "loki"
  version    = "6.46.0"
  namespace  = var.metrics_ns

  values = [templatefile("${path.module}/templates/loki.values.tftpl", {
    ca_hash = local.ca_hash
  })]
}
