resource "helm_release" "mimir" {
  name       = "mimir"
  repository = "https://grafana.github.io/helm-charts"
  chart      = "mimir-distributed"
  version    = "5.6.0"
  namespace  = var.metrics_ns

  values = [templatefile("${path.module}/templates/mimir.values.tftpl", {
    ca_hash   = local.ca_hash
    namespace = var.metrics_ns
  })]
}
