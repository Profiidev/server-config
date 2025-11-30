resource "helm_release" "alert_bot" {
  name       = "alert-bot"
  repository = "https://k8s-at-home.com/charts"
  chart      = "alertmanager-discord"
  version    = "1.3.2"
  namespace  = var.metrics_ns

  values = [templatefile("${path.module}/templates/alert-bot.values.tftpl", {})]
}

resource "kubectl_manifest" "discord_webhook" {
  yaml_body = <<YAML
apiVersion: external-secrets.io/v1
kind: ExternalSecret
metadata:
  name: discord-webhook
  namespace: ${var.metrics_ns}
spec:
  refreshInterval: 15s
  secretStoreRef:
    name: ${var.cluster_secret_store}
    kind: ClusterSecretStore
  target:
    name: discord-webhook
  dataFrom:
  - extract:
      key: apps/alert-bot
  YAML
}

module "external_np_alert_bot" {
  source = "../modules/external-np"

  namespace = var.metrics_ns
}
