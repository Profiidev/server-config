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

module "ingress_nginx_dashboard" {
  source = "../modules/grafana-dashboard"

  name      = "ingress-nginx"
  namespace = var.metrics_ns

  depends_on = [kubernetes_namespace.metrics_ns]
}

module "ingress_nginx_request_dashboard" {
  source = "../modules/grafana-dashboard"

  name      = "ingress-nginx-request"
  namespace = var.metrics_ns

  depends_on = [kubernetes_namespace.metrics_ns]
}

module "cert_manager_dashboard" {
  source = "../modules/grafana-dashboard"

  name      = "cert-manager"
  namespace = var.metrics_ns

  depends_on = [kubernetes_namespace.metrics_ns]
}

module "external_secrets_dashboard" {
  source = "../modules/grafana-dashboard"

  name      = "external-secrets"
  namespace = var.metrics_ns

  depends_on = [kubernetes_namespace.metrics_ns]
}

module "vault_dashboard" {
  source = "../modules/grafana-dashboard"

  name      = "vault"
  namespace = var.metrics_ns

  depends_on = [kubernetes_namespace.metrics_ns]
}

module "longhorn_dashboard" {
  source = "../modules/grafana-dashboard"

  name      = "longhorn"
  namespace = var.metrics_ns

  depends_on = [kubernetes_namespace.metrics_ns]
}

module "minio_dashboard" {
  source = "../modules/grafana-dashboard"

  name      = "minio"
  namespace = var.metrics_ns

  depends_on = [kubernetes_namespace.metrics_ns]
}

module "postgres_dashboard" {
  source = "../modules/grafana-dashboard"

  name      = "postgres"
  namespace = var.metrics_ns

  depends_on = [kubernetes_namespace.metrics_ns]
}

module "pgbouncer_dashboard" {
  source = "../modules/grafana-dashboard"

  name      = "pgbouncer"
  namespace = var.metrics_ns

  depends_on = [kubernetes_namespace.metrics_ns]
}

module "pgbouncer_overview_dashboard" {
  source = "../modules/grafana-dashboard"

  name      = "pgbouncer-overview"
  namespace = var.metrics_ns

  depends_on = [kubernetes_namespace.metrics_ns]
}

module "nats_dashboard" {
  source = "../modules/grafana-dashboard"

  name      = "nats"
  namespace = var.metrics_ns

  depends_on = [kubernetes_namespace.metrics_ns]
}

module "nats_jetstream_dashboard" {
  source = "../modules/grafana-dashboard"

  name      = "nats-jetstream"
  namespace = var.metrics_ns

  depends_on = [kubernetes_namespace.metrics_ns]
}

module "coderd_dashboard" {
  source = "../modules/grafana-dashboard"

  name      = "coderd"
  namespace = var.metrics_ns

  depends_on = [kubernetes_namespace.metrics_ns]
}

module "coder_workspaces_dashboard" {
  source = "../modules/grafana-dashboard"

  name      = "coder-workspaces"
  namespace = var.metrics_ns

  depends_on = [kubernetes_namespace.metrics_ns]
}

module "coder_workspace_detail_dashboard" {
  source = "../modules/grafana-dashboard"

  name      = "coder-workspace-detail"
  namespace = var.metrics_ns

  depends_on = [kubernetes_namespace.metrics_ns]
}

module "loki_dashboard" {
  source = "../modules/grafana-dashboard"

  name      = "loki-logs"
  namespace = var.metrics_ns

  depends_on = [kubernetes_namespace.metrics_ns]
}

resource "kubectl_manifest" "cert_manager_prometheus_config" {
  yaml_body = yamlencode({
    apiVersion = "monitoring.coreos.com/v1"
    kind       = "PrometheusRule"
    metadata = {
      name      = "cert-manager"
      namespace = var.metrics_ns
    }
    spec = yamldecode(file("${path.module}/mixin/cert-manager.yaml"))
  })

  depends_on = [kubernetes_namespace.metrics_ns]
}

resource "kubectl_manifest" "longhorn_prometheus_config" {
  yaml_body = yamlencode({
    apiVersion = "monitoring.coreos.com/v1"
    kind       = "PrometheusRule"
    metadata = {
      name      = "longhorn"
      namespace = var.metrics_ns
      labels = {
        prometheus = "longhorn"
        role       = "alert-rules"
      }
    }
    spec = yamldecode(file("${path.module}/mixin/longhorn.yaml"))
  })

  depends_on = [kubernetes_namespace.metrics_ns]
}

resource "kubectl_manifest" "minio_prometheus_config" {
  yaml_body = yamlencode({
    apiVersion = "monitoring.coreos.com/v1"
    kind       = "PrometheusRule"
    metadata = {
      name      = "minio"
      namespace = var.metrics_ns
      labels = {
        prometheus = "minio"
        role       = "alert-rules"
      }
    }
    spec = yamldecode(file("${path.module}/mixin/minio.yaml"))
  })

  depends_on = [kubernetes_namespace.metrics_ns]
}

resource "kubectl_manifest" "postgres_prometheus_config" {
  yaml_body = yamlencode({
    apiVersion = "monitoring.coreos.com/v1"
    kind       = "PrometheusRule"
    metadata = {
      name      = "postgres"
      namespace = var.metrics_ns
      labels = {
        prometheus = "postgres"
        role       = "alert-rules"
      }
    }
    spec = yamldecode(file("${path.module}/mixin/postgres.yaml"))
  })

  depends_on = [kubernetes_namespace.metrics_ns]
}

resource "kubectl_manifest" "pgbouncer_prometheus_config" {
  yaml_body = yamlencode({
    apiVersion = "monitoring.coreos.com/v1"
    kind       = "PrometheusRule"
    metadata = {
      name      = "pgbouncer"
      namespace = var.metrics_ns
      labels = {
        prometheus = "pgbouncer"
        role       = "alert-rules"
      }
    }
    spec = yamldecode(file("${path.module}/mixin/pgbouncer.yaml"))
  })

  depends_on = [kubernetes_namespace.metrics_ns]
}

resource "kubectl_manifest" "coder_prometheus_config" {
  yaml_body = yamlencode({
    apiVersion = "monitoring.coreos.com/v1"
    kind       = "PrometheusRule"
    metadata = {
      name      = "coder"
      namespace = var.metrics_ns
      labels = {
        prometheus = "coder"
        role       = "alert-rules"
      }
    }
    spec = yamldecode(file("${path.module}/mixin/coder.yaml"))
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
