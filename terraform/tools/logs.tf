resource "helm_release" "loki" {
  name       = "loki"
  repository = "https://grafana.github.io/helm-charts"
  chart      = "loki"
  version    = "6.29.0"
  namespace  = var.metrics_ns

  values = [templatefile("${path.module}/templates/loki.values.tftpl", {
    ca_hash = var.ca_hash
  })]

  depends_on = [kubernetes_namespace.metrics_ns]
}

resource "helm_release" "promtail" {
  name       = "promtail"
  repository = "https://grafana.github.io/helm-charts"
  chart      = "promtail"
  version    = "6.16.6"
  namespace  = var.metrics_ns

  values = [templatefile("${path.module}/templates/promtail.values.tftpl", {})]

  depends_on = [kubernetes_namespace.metrics_ns]
}

resource "kubernetes_config_map_v1" "loki_datasource" {
  metadata {
    name      = "loki-datasource"
    namespace = var.metrics_ns
    labels = {
      "grafana_datasource" = "1"
    }
  }

  data = {
    "loki-stack-datasource.yaml" = <<YAML
      apiVersion: 1
      datasources:
      - name: Loki
        type: loki
        access: proxy
        url: "http://loki-read.${var.metrics_ns}.svc.cluster.local:3100"
        version: 1
        isDefault: false
        jsonData:
          httpHeaderName1: 'X-Scope-OrgID'
        secureJsonData:
          httpHeaderValue1: '1'
    YAML
  }
}

resource "kubectl_manifest" "loki_secrets" {
  yaml_body = <<YAML
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: loki-secrets
  namespace: ${var.metrics_ns}
spec:
  refreshInterval: 15s
  secretStoreRef:
    name: ${var.cluster_secret_store}
    kind: ClusterSecretStore
  target:
    name: loki-secrets
  dataFrom:
  - extract:
      key: apps/loki
  YAML

  depends_on = [kubernetes_namespace.metrics_ns]
}

module "loki_dashboard" {
  source = "./dashboard"

  name      = "loki-logs"
  namespace = var.metrics_ns
  url       = ""
  download  = false

  depends_on = [kubernetes_namespace.metrics_ns]
}
