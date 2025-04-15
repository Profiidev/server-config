resource "kubernetes_namespace" "metrics_ns" {
  metadata {
    name = var.metrics_ns
    labels = {
      "${var.oidc_access_label.key}"     = var.oidc_access_label.value
      "${var.cloudflare_cert_label.key}" = var.cloudflare_cert_label.value
      "${var.secret_store_label.key}"    = var.secret_store_label.value
      "${var.cluster_ca_cert_label.key}" = var.cluster_ca_cert_label.value
    }
  }
}

resource "helm_release" "prometheus" {
  name       = "prometheus"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  version    = "70.4.2"
  namespace  = var.metrics_ns

  values = [templatefile("${path.module}/templates/prometheus.values.tftpl", {
    namespace              = var.metrics_ns
    cloudflare_ca_cert_var = var.cloudflare_ca_cert_var
    cloudflare_cert_var    = var.cloudflare_cert_var
    ingress_class          = var.ingress_class
    storage_class          = var.storage_class
  })]

  depends_on = [kubernetes_namespace.metrics_ns]
}

resource "helm_release" "alert_bot" {
  name       = "alert-bot"
  repository = "https://k8s-at-home.com/charts"
  chart      = "alertmanager-discord"
  version    = "1.3.2"
  namespace  = var.metrics_ns

  values = [templatefile("${path.module}/templates/alert-bot.values.tftpl", {})]
}

resource "kubectl_manifest" "prometheus_k8s_api_egress" {
  yaml_body = <<YAML
apiVersion: crd.projectcalico.org/v1
kind: NetworkPolicy
metadata:
  name: k8s-api-egress
  namespace: ${var.metrics_ns}
spec:
  order: 10
  types:
    - Egress
  egress:
    - action: Allow
      protocol: TCP
      destination:
        nets:
          - 194.164.200.60/32
        ports:
          - 6443
          - 9100
          - 10249
          - 10250
          - 10254
          - 10257
          - 10259
          - 2381
  YAML

  depends_on = [kubernetes_namespace.metrics_ns]
}

resource "kubectl_manifest" "metrics_ns" {
  yaml_body = <<YAML
apiVersion: crd.projectcalico.org/v1
kind: NetworkPolicy
metadata:
  name: metrics-namespace
  namespace: ${var.metrics_ns}
spec:
  order: 10
  namespaceSelector: kubernetes.io/metadata.name == '${var.metrics_ns}'
  types:
    - Egress
    - Ingress
  egress:
    - action: Allow
      protocol: TCP
      destination:
        namespaceSelector: kubernetes.io/metadata.name == '${var.metrics_ns}'
  ingress:
    - action: Allow
      protocol: TCP
      source:
        namespaceSelector: kubernetes.io/metadata.name == '${var.metrics_ns}'
  YAML

  depends_on = [kubernetes_namespace.metrics_ns]
}

resource "kubectl_manifest" "metrics_oidc" {
  yaml_body = <<YAML
apiVersion: crd.projectcalico.org/v1
kind: NetworkPolicy
metadata:
  name: metrics-oidc
  namespace: ${var.metrics_ns}
spec:
  order: 10
  selector: app.kubernetes.io/name == 'grafana'
  types:
    - Egress
  egress:
    - action: Allow
      protocol: TCP
      destination:
        namespaceSelector: kubernetes.io/metadata.name == '${var.positron_ns}'
        selector: app == 'positron-backend'
        ports:
          - 8000
  YAML

  depends_on = [kubernetes_namespace.metrics_ns]
}

resource "kubectl_manifest" "metrics_ingress" {
  yaml_body = <<YAML
apiVersion: crd.projectcalico.org/v1
kind: NetworkPolicy
metadata:
  name: metrics-ingress
  namespace: ${var.metrics_ns}
spec:
  order: 10
  selector: app.kubernetes.io/name == 'grafana'
  types:
    - Ingress
  ingress:
    - action: Allow
      protocol: TCP
      source:
        namespaceSelector: kubernetes.io/metadata.name == 'kube-system'
        selector: app.kubernetes.io/name == 'rke2-ingress-nginx'
      destination:
        ports:
          - 3000
  YAML

  depends_on = [kubernetes_namespace.metrics_ns]
}

resource "kubectl_manifest" "metrics_egress" {
  yaml_body = <<YAML
apiVersion: crd.projectcalico.org/v1
kind: GlobalNetworkPolicy
metadata:
  name: metrics-egress
spec:
  namespaceSelector: kubernetes.io/metadata.name == '${var.metrics_ns}'
  selector: app.kubernetes.io/name == 'grafana'
  types:
    - Egress
  egress:
    - action: Allow
      protocol: TCP
      destination:
        ports:
          - 443
        domains:
          - grafana.com
  YAML

  depends_on = [kubernetes_namespace.metrics_ns]
}

resource "kubectl_manifest" "alert_egress" {
  yaml_body = <<YAML
apiVersion: crd.projectcalico.org/v1
kind: GlobalNetworkPolicy
metadata:
  name: alert-egress
spec:
  namespaceSelector: kubernetes.io/metadata.name == '${var.metrics_ns}'
  selector: app.kubernetes.io/name == 'alertmanager' || app.kubernetes.io/name == 'alertmanager-discord'
  types:
    - Egress
  egress:
    - action: Allow
      protocol: TCP
      destination:
        ports:
          - 443
        domains:
          - discord.com
  YAML

  depends_on = [kubernetes_namespace.metrics_ns]
}

module "ingress_nginx_metrics" {
  source = "./metrics-np"

  namespace  = "kube-system"
  port       = 9153
  name       = "rke2-coredns"
  metrics_ns = var.metrics_ns

  depends_on = [kubernetes_namespace.metrics_ns]
}

module "cert_manager_metrics" {
  source = "./metrics-np"

  namespace  = var.cert_ns
  port       = 9402
  name       = "cert-manager"
  metrics_ns = var.metrics_ns

  depends_on = [kubernetes_namespace.metrics_ns]
}

module "external_secrets_metrics" {
  source = "./metrics-np"

  namespace  = var.secrets_ns
  port       = 8080
  name       = "external-secrets"
  metrics_ns = var.metrics_ns

  depends_on = [kubernetes_namespace.metrics_ns]
}

module "vault_metrics" {
  source = "./metrics-np"

  namespace  = var.secrets_ns
  port       = 8200
  name       = "vault"
  metrics_ns = var.metrics_ns

  depends_on = [kubernetes_namespace.metrics_ns]
}

module "longhorn_metrics" {
  source = "./metrics-np"

  namespace  = var.storage_ns
  port       = 9500
  name       = "longhorn"
  metrics_ns = var.metrics_ns

  depends_on = [kubernetes_namespace.metrics_ns]
}

module "minio_metrics" {
  source = "./metrics-np"

  namespace  = var.minio_ns
  port       = 9000
  name       = "minio"
  metrics_ns = var.metrics_ns
  selector   = "has(v1.min.io/tenant)"

  depends_on = [kubernetes_namespace.metrics_ns]
}

module "stalwart_metrics" {
  source = "./metrics-np"

  namespace  = var.stalwart_ns
  port       = 8080
  name       = "stalwart"
  metrics_ns = var.metrics_ns
  selector   = "app == 'stalwart'"

  depends_on = [kubernetes_namespace.metrics_ns]
}

module "postgres_metrics" {
  source = "./metrics-np"

  namespace  = var.everest_ns
  port       = 9187
  name       = "prometheus-postgres-exporter"
  metrics_ns = var.metrics_ns
  selector   = "app == 'prometheus-postgres-exporter'"

  depends_on = [kubernetes_namespace.metrics_ns]
}

module "pgbouncer_metrics" {
  source = "./metrics-np"

  namespace  = var.everest_ns
  port       = 9127
  name       = "prometheus-pgbouncer-exporter"
  metrics_ns = var.metrics_ns
  selector   = "app == 'prometheus-pgbouncer-exporter'"

  depends_on = [kubernetes_namespace.metrics_ns]
}

module "ingress_nginx_dashboard" {
  source = "./dashboard"

  name      = "ingress-nginx"
  namespace = var.metrics_ns
  url       = "https://raw.githubusercontent.com/kubernetes/ingress-nginx/refs/heads/main/deploy/grafana/dashboards/nginx.json"

  depends_on = [kubernetes_namespace.metrics_ns]
}

module "ingress_nginx_request_dashboard" {
  source = "./dashboard"

  name      = "ingress-nginx-request"
  namespace = var.metrics_ns
  url       = "https://raw.githubusercontent.com/kubernetes/ingress-nginx/refs/heads/main/deploy/grafana/dashboards/request-handling-performance.json"

  depends_on = [kubernetes_namespace.metrics_ns]
}

module "cert_manager_dashboard" {
  source = "./dashboard"

  name      = "cert-manager"
  namespace = var.metrics_ns
  url       = ""
  download  = false

  depends_on = [kubernetes_namespace.metrics_ns]
}

module "external_secrets_dashboard" {
  source = "./dashboard"

  name      = "external-secrets"
  namespace = var.metrics_ns
  url       = "https://raw.githubusercontent.com/external-secrets/external-secrets/main/docs/snippets/dashboard.json"

  depends_on = [kubernetes_namespace.metrics_ns]
}

module "vault_dashboard" {
  source = "./dashboard"

  name      = "vault"
  namespace = var.metrics_ns
  url       = ""
  download  = false

  depends_on = [kubernetes_namespace.metrics_ns]
}

module "longhorn_dashboard" {
  source = "./dashboard"

  name      = "longhorn"
  namespace = var.metrics_ns
  url       = "https://grafana.com/api/dashboards/16888/revisions/9/download"

  depends_on = [kubernetes_namespace.metrics_ns]
}

module "minio_dashboard" {
  source = "./dashboard"

  name      = "minio"
  namespace = var.metrics_ns
  url       = "https://raw.githubusercontent.com/minio/minio/master/docs/metrics/prometheus/grafana/minio-dashboard.json"
  download  = false

  depends_on = [kubernetes_namespace.metrics_ns]
}

module "postgres_dashboard" {
  source = "./dashboard"

  name      = "postgres"
  namespace = var.metrics_ns
  url       = ""
  download  = false

  depends_on = [kubernetes_namespace.metrics_ns]
}

module "pgbouncer_dashboard" {
  source = "./dashboard"

  name      = "pgbouncer"
  namespace = var.metrics_ns
  url       = "https://raw.githubusercontent.com/monitoring-mixins/website/refs/heads/master/assets/pgbouncer/dashboards/clusterOverview"
  download  = false

  depends_on = [kubernetes_namespace.metrics_ns]
}

module "pgbouncer_overview_dashboard" {
  source = "./dashboard"

  name      = "pgbouncer-overview"
  namespace = var.metrics_ns
  url       = "https://raw.githubusercontent.com/monitoring-mixins/website/refs/heads/master/assets/pgbouncer/dashboards/overview"
  download  = false

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

resource "kubectl_manifest" "alert_manager_config" {
  yaml_body = <<YAML
apiVersion: monitoring.coreos.com/v1alpha1
kind: AlertmanagerConfig
metadata:
  name: alert-manager-config
  namespace: ${var.metrics_ns}
  labels:
    alertmanagerConfig: alert-manager-config
spec:
  route:
    groupBy: ['job']
    groupWait: 30s
    groupInterval: 5m
    repeatInterval: 12h
    receiver: 'discord'
    routes:
      - receiver: 'null'
        matchers:
        - matchType: "="
          name: alertname
          value: Watchdog
  receivers:
  - name: 'null'
  - name: 'discord'
    webhookConfigs:
    - urlSecret:
        name: discord-webhook
        key: proxy
      sendResolved: true
  YAML

  depends_on = [kubernetes_namespace.metrics_ns]
}

resource "kubectl_manifest" "discord_webhook" {
  yaml_body = <<YAML
apiVersion: external-secrets.io/v1beta1
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

  depends_on = [helm_release.prometheus]
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

  depends_on = [helm_release.prometheus]
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
