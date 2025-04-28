
resource "kubernetes_namespace" "metrics_ns" {
  metadata {
    name = var.metrics_ns
    labels = {
      "${var.oidc_access_label.key}"     = var.oidc_access_label.value
      "${var.cloudflare_cert_label.key}" = var.cloudflare_cert_label.value
      "${var.secret_store_label.key}"    = var.secret_store_label.value
      "${var.cluster_ca_cert_label.key}" = var.cluster_ca_cert_label.value
      "${var.minio_access_label.key}"    = var.minio_access_label.value
    }
  }
}

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

resource "helm_release" "mimir" {
  name       = "mimir"
  repository = "https://grafana.github.io/helm-charts"
  chart      = "mimir-distributed"
  version    = "5.6.0"
  namespace  = var.metrics_ns

  values = [templatefile("${path.module}/templates/mimir.values.tftpl", {
    ca_hash = var.ca_hash
  })]

  depends_on = [kubernetes_namespace.metrics_ns]
}

resource "helm_release" "tempo" {
  name       = "tempo"
  repository = "https://grafana.github.io/helm-charts"
  chart      = "tempo-distributed"
  version    = "1.34.0"
  namespace  = var.metrics_ns

  values = [templatefile("${path.module}/templates/tempo.values.tftpl", {
    ca_hash = var.ca_hash
  })]

  depends_on = [kubernetes_namespace.metrics_ns]
}

resource "helm_release" "alloy" {
  name       = "alloy"
  repository = "https://grafana.github.io/helm-charts"
  chart      = "alloy"
  version    = "0.12.6"
  namespace  = var.metrics_ns

  values = [templatefile("${path.module}/templates/alloy.values.tftpl", {
    ca_hash = var.ca_hash
  })]

  depends_on = [kubernetes_namespace.metrics_ns]
}

resource "helm_release" "grafana" {
  name       = "grafana"
  repository = "https://grafana.github.io/helm-charts"
  chart      = "grafana"
  version    = "8.11.3"
  namespace  = var.metrics_ns

  values = [templatefile("${path.module}/templates/grafana.values.tftpl", {
    namespace              = var.metrics_ns
    storage_class          = var.storage_class
    ingress_class          = var.ingress_class
    cloudflare_ca_cert_var = var.cloudflare_ca_cert_var
    cloudflare_cert_var    = var.cloudflare_cert_var
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

resource "helm_release" "promtail" {
  name       = "promtail"
  repository = "https://grafana.github.io/helm-charts"
  chart      = "promtail"
  version    = "6.16.6"
  namespace  = var.metrics_ns

  values = [templatefile("${path.module}/templates/promtail.values.tftpl", {})]

  depends_on = [kubernetes_namespace.metrics_ns]
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
          - "*.grafana.com"
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

resource "kubectl_manifest" "lgtm_secrets" {
  yaml_body = <<YAML
apiVersion: external-secrets.io/v1beta1
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

  depends_on = [kubernetes_namespace.metrics_ns]
}
