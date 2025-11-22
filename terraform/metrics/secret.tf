resource "kubectl_manifest" "lgtm_secrets" {
  yaml_body = <<YAML
apiVersion: external-secrets.io/v1
kind: ExternalSecret
metadata:
  name: lgtm
  namespace: ${var.metrics_ns}
spec:
  refreshInterval: 15s
  secretStoreRef:
    name: ${var.cluster_secret_store}
    kind: ClusterSecretStore
  target:
    name: lgtm
  dataFrom:
  - extract:
      key: apps/lgtm
  YAML
}
