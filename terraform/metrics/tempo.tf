resource "helm_release" "tempo" {
  count = 0

  name       = "tempo"
  repository = "oci://ghcr.io/grafana-community/helm-charts"
  chart      = "tempo"
  version    = "2.3.0"
  namespace  = var.metrics_ns

  values = [templatefile("${path.module}/templates/tempo.values.tftpl", {
    ca_hash = local.ca_hash
  })]
}
