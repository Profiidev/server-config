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
resource "kubectl_manifest" "grafana_tls_options" {
  yaml_body = <<YAML
apiVersion: traefik.io/v1alpha1
kind: TLSOption
metadata:
  name: grafana-tls-options
  namespace: ${var.metrics_ns}
spec:
  clientAuth:
    clientAuthType: RequireAndVerifyClientCert
    secretNames:
      - ${var.cloudflare_ca_cert_var}
  YAML
}

module "dashboards" {
  for_each = toset([
    "ingress-nginx",
    "ingress-nginx-request",
    "cert-manager",
    "external-secrets",
    "vault", "longhorn",
    "postgres",
    "nats",
    "nats-jetstream",
    "coderd",
    "coder-workspaces",
    "coder-workspace-detail",
    "crowdsec-details",
    "crowdsec-insight",
    "crowdsec-overview",
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
}

resource "kubectl_manifest" "alert_configs" {
  for_each = toset([
    "cert-manager",
    "longhorn",
    "postgres",
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
}
