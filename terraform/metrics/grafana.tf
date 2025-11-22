resource "helm_release" "grafana" {
  name       = "grafana"
  repository = "https://grafana.github.io/helm-charts"
  chart      = "grafana"
  version    = "10.2.0"
  namespace  = var.metrics_ns

  values = [templatefile("${path.module}/templates/grafana.values.tftpl", {
    namespace              = var.metrics_ns
    storage_class          = var.storage_class
    ingress_class          = var.ingress_class
    cloudflare_ca_cert_var = var.cloudflare_ca_cert_var
    cloudflare_cert_var    = var.cloudflare_cert_var
  })]
}
