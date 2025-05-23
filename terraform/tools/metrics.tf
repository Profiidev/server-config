module "ingress_nginx_metrics" {
  source = "../modules/metrics-np"

  namespace  = "kube-system"
  port       = 9153
  name       = "rke2-coredns"
  metrics_ns = var.metrics_ns

  depends_on = [kubernetes_namespace.metrics_ns]
}

module "cert_manager_metrics" {
  source = "../modules/metrics-np"

  namespace  = var.cert_ns
  port       = 9402
  name       = "cert-manager"
  metrics_ns = var.metrics_ns

  depends_on = [kubernetes_namespace.metrics_ns]
}

module "external_secrets_metrics" {
  source = "../modules/metrics-np"

  namespace  = var.secrets_ns
  port       = 8080
  name       = "external-secrets"
  metrics_ns = var.metrics_ns

  depends_on = [kubernetes_namespace.metrics_ns]
}

module "vault_metrics" {
  source = "../modules/metrics-np"

  namespace  = var.secrets_ns
  port       = 8200
  name       = "vault"
  metrics_ns = var.metrics_ns

  depends_on = [kubernetes_namespace.metrics_ns]
}

module "longhorn_metrics" {
  source = "../modules/metrics-np"

  namespace  = var.storage_ns
  port       = 9500
  name       = "longhorn"
  metrics_ns = var.metrics_ns

  depends_on = [kubernetes_namespace.metrics_ns]
}

module "minio_metrics" {
  source = "../modules/metrics-np"

  namespace  = var.minio_ns
  port       = 9000
  name       = "minio"
  metrics_ns = var.metrics_ns
  selector   = "has(v1.min.io/tenant)"

  depends_on = [kubernetes_namespace.metrics_ns]
}

module "stalwart_metrics" {
  source = "../modules/metrics-np"

  namespace  = var.stalwart_ns
  port       = 8080
  name       = "stalwart"
  metrics_ns = var.metrics_ns
  selector   = "app == 'stalwart'"

  depends_on = [kubernetes_namespace.metrics_ns]
}

module "postgres_metrics" {
  source = "../modules/metrics-np"

  namespace  = var.everest_ns
  port       = 9187
  name       = "prometheus-postgres-exporter"
  metrics_ns = var.metrics_ns
  selector   = "app == 'prometheus-postgres-exporter'"

  depends_on = [kubernetes_namespace.metrics_ns]
}

module "pgbouncer_metrics" {
  source = "../modules/metrics-np"

  namespace  = var.everest_ns
  port       = 9127
  name       = "prometheus-pgbouncer-exporter"
  metrics_ns = var.metrics_ns
  selector   = "app == 'prometheus-pgbouncer-exporter'"

  depends_on = [kubernetes_namespace.metrics_ns]
}

module "nats_metrics" {
  source = "../modules/metrics-np"

  namespace  = var.nats_ns
  port       = 7777
  name       = "nats"
  metrics_ns = var.metrics_ns
  selector   = "app.kubernetes.io/component == 'nats'"

  depends_on = [kubernetes_namespace.metrics_ns]
}

module "longhorn_proxy_metrics" {
  source = "../modules/metrics-np"

  namespace  = var.storage_ns
  port       = 44180
  name       = "longhorn-proxy"
  metrics_ns = var.metrics_ns
  selector   = "app == 'oauth2-proxy'"

  depends_on = [kubernetes_namespace.metrics_ns]
}

module "coder_metrics" {
  source = "../modules/metrics-np"

  namespace  = var.coder_ns
  port       = 2112
  name       = "coder"
  metrics_ns = var.metrics_ns
  selector   = "app.kubernetes.io/name == 'coder'"

  depends_on = [kubernetes_namespace.metrics_ns]
}

module "argocd_metrics" {
  source = "../modules/metrics-np"

  namespace  = var.argo_ns
  port       = 8083
  ports      = [8082, 8080, 9001, 8084]
  name       = "argocd"
  metrics_ns = var.metrics_ns

  depends_on = [kubernetes_namespace.metrics_ns]
}

module "dashboards" {
  for_each = toset([
    "ingress-nginx",
    "ingress-nginx-request",
    "cert-manager",
    "external-secrets",
    "vault", "longhorn",
    "minio",
    "postgres",
    "pgbouncer",
    "pgbouncer-overview",
    "nats",
    "nats-jetstream",
    "coderd",
    "coder-workspaces",
    "coder-workspace-detail",
    "pod-logs",
    "tempo-block-builder",
    "tempo-operational",
    "tempo-reads",
    "tempo-resources",
    "tempo-rollout-progress",
    "tempo-tenants",
    "tempo-writes",
    "alloy-controller",
    "alloy-logs",
    "alloy-otel",
    "alloy-prom",
    "alloy-resources",
    "loki-chunks",
    "loki-deletion",
    "loki-logs",
    "loki-operational",
    "loki-reads-resources",
    "loki-reads",
    "loki-retention",
    "loki-writes-resources",
    "loki-writes",
    "argo-cd-application",
    "argo-cd-notifications",
    "argo-cd-operational",
  ])

  source = "../modules/grafana-dashboard"

  name      = each.key
  namespace = var.metrics_ns

  depends_on = [kubernetes_namespace.metrics_ns]
}

resource "kubectl_manifest" "alert_configs" {
  for_each = toset([
    "cert-manager",
    "longhorn",
    "minio",
    "postgres",
    "pgbouncer",
    "coder",
    "tempo",
    "alloy",
    "argocd",
  ])

  yaml_body = yamlencode({
    apiVersion = "monitoring.coreos.com/v1"
    kind       = "PrometheusRule"
    metadata = {
      name      = each.key
      namespace = var.metrics_ns
      labels = {
        prometheus = each.key
        role       = "alert-rules"
      }
    }
    spec = yamldecode(file("${path.module}/mixin/${each.key}.yaml"))
  })

  depends_on = [kubernetes_namespace.metrics_ns]
}

resource "helm_release" "postgres_exporter" {
  name       = "postgres-exporter"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "prometheus-postgres-exporter"
  version    = "6.10.0"
  namespace  = var.everest_ns

  values = [templatefile("${path.module}/templates/postgres-exporter.values.tftpl", {
    namespace = var.everest_ns
  })]
}

resource "helm_release" "pgbouncer_exporter" {
  name       = "pgbouncer-exporter"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "prometheus-pgbouncer-exporter"
  version    = "0.6.0"
  namespace  = var.everest_ns

  values = [templatefile("${path.module}/templates/pgbouncer-exporter.values.tftpl", {
    namespace = var.everest_ns
  })]
}

resource "kubectl_manifest" "postgres_exporter_secret" {
  yaml_body = <<YAML
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: postgres-exporter
  namespace: ${var.everest_ns}
spec:
  refreshInterval: 15s
  secretStoreRef:
    name: ${var.cluster_secret_store}
    kind: ClusterSecretStore
  target:
    name: postgres-exporter
  dataFrom:
  - extract:
      key: apps/postgres-exporter
  YAML
}

resource "kubectl_manifest" "pgbouncer_exporter_secret" {
  yaml_body = <<YAML
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: pgbouncer-exporter
  namespace: ${var.everest_ns}
spec:
  refreshInterval: 15s
  secretStoreRef:
    name: ${var.cluster_secret_store}
    kind: ClusterSecretStore
  target:
    name: pgbouncer-exporter
  dataFrom:
  - extract:
      key: apps/pgbouncer-exporter
  YAML
}
