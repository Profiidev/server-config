resource "helm_release" "mimir" {
  name       = "mimir"
  repository = "https://grafana.github.io/helm-charts"
  chart      = "mimir-distributed"
  version    = "6.0.6"
  namespace  = var.metrics_ns

  values = [templatefile("${path.module}/templates/mimir.values.tftpl", {
    ca_hash   = local.ca_hash
    namespace = var.metrics_ns
  })]
}

resource "kubectl_manifest" "discord_webhook" {
  yaml_body = <<YAML
apiVersion: external-secrets.io/v1
kind: ExternalSecret
metadata:
  name: discord-webhook
  namespace: ${var.metrics_ns}
spec:
  refreshInterval: 5m
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
