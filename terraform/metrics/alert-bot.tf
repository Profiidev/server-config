resource "helm_release" "alert_bot" {
  name       = "alert-bot"
  repository = "https://k8s-at-home.com/charts"
  chart      = "alertmanager-discord"
  version    = "1.3.2"
  namespace  = var.metrics_ns

  values = [templatefile("${path.module}/templates/alert-bot.values.tftpl", {})]
}

module "external_np_alert_bot" {
  source = "../modules/external-np"

  namespace = var.metrics_ns
}
