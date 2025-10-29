resource "kubernetes_namespace" "minio" {
  metadata {
    name = var.minio_ns
    labels = {
      "${var.minio_config_label.key}" = var.minio_config_label.value
    }
  }
}

resource "helm_release" "minio" {
  name       = "minio"
  repository = "https://operator.min.io"
  chart      = "operator"
  version    = "7.0.1"
  namespace  = var.minio_ns

  values = [templatefile("${path.module}/templates/minio.values.tftpl", {
  })]

  depends_on = [kubernetes_namespace.minio]
}

resource "helm_release" "minio_tenant" {
  name       = "minio-tenant"
  repository = "https://operator.min.io"
  chart      = "tenant"
  version    = "7.0.1"
  namespace  = var.minio_ns

  values = [templatefile("${path.module}/templates/minio-tenant.values.tftpl", {
    storage_class          = var.storage_class
    namespace              = var.minio_ns
    cloudflare_ca_cert_var = var.cloudflare_ca_cert_var
    cloudflare_cert_var    = var.cloudflare_cert_var
    ingress_class          = var.ingress_class
    minio_config           = var.minio_config
    cert_issuer            = var.cert_issuer_prod
  })]

  depends_on = [kubernetes_namespace.minio]
}

module "k8s_api_np_minio" {
  source = "../modules/k8s-api-np"

  namespace = var.minio_ns
  k8s_api   = var.k8s_api

  depends_on = [kubernetes_namespace.minio]
}

resource "kubectl_manifest" "minio_config" {
  yaml_body = <<YAML
apiVersion: external-secrets.io/v1
kind: ExternalSecret
metadata:
  name: ${var.minio_config}
  namespace: ${var.minio_ns}
spec:
  refreshTime: 15s
  secretStoreRef:
    name: ${var.cluster_secret_store}
    kind: ClusterSecretStore
  target:
    name: ${var.minio_config}
  data:
    - secretKey: config.env
      remoteRef:
        key: db/minio_config
        property: config.env
  YAML
}

resource "kubectl_manifest" "minio_metrics" {
  yaml_body = <<YAML
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: minio
  namespace: ${var.minio_ns}
spec:
  selector:
    matchLabels:
      app: minio-metrics
  endpoints:
    - port: https-minio
      interval: 60s
      path: /minio/v2/metrics/cluster
      scheme: https
      tlsConfig:
        insecureSkipVerify: true
      bearerTokenSecret:
        name: minio-metrics
        key: token
  YAML

  depends_on = [kubernetes_namespace.minio_ns]
}

resource "kubectl_manifest" "minio_metrics_secret" {
  yaml_body = <<YAML
apiVersion: external-secrets.io/v1
kind: ExternalSecret
metadata:
  name: minio-metrics
  namespace: ${var.minio_ns}
spec:
  refreshInterval: 15s
  secretStoreRef:
    name: ${var.cluster_secret_store}
    kind: ClusterSecretStore
  target:
    name: minio-metrics
  dataFrom:
  - extract:
      key: db/minio_metrics
  YAML

  depends_on = [kubernetes_namespace.minio_ns]
}
