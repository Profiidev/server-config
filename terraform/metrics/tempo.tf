resource "helm_release" "tempo" {
  name       = "tempo"
  repository = "https://grafana.github.io/helm-charts"
  chart      = "tempo"
  version    = "1.24.1"
  namespace  = var.metrics_ns

  values = [templatefile("${path.module}/templates/tempo.values.tftpl", {
    ca_hash = local.ca_hash
  })]
}
