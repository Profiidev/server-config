resource "helm_release" "alloy" {
  name       = "alloy"
  repository = "https://grafana.github.io/helm-charts"
  chart      = "alloy"
  version    = "1.4.0"
  namespace  = var.metrics_ns

  values = [templatefile("${path.module}/templates/alloy.values.tftpl", {
    ca_hash = local.ca_hash
  })]
}
