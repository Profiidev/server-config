resource "kubernetes_namespace" "minio_ns" {
  metadata {
    name = var.minio_ns
    labels = {
      "${var.cloudflare_cert_label.key}" = var.cloudflare_cert_label.value
      "${var.secret_store_label.key}"    = var.secret_store_label.value
      "${var.minio_config_label.key}"    = var.minio_config_label.value
      "${var.oidc_access_label.key}"     = var.oidc_access_label.value
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
    metrics_ns = var.metrics_ns
  })]

  depends_on = [kubernetes_namespace.minio_ns]
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

  depends_on = [kubernetes_namespace.minio_ns]
}

resource "kubectl_manifest" "minio_tenant" {
  yaml_body = <<YAML
apiVersion: crd.projectcalico.org/v1
kind: NetworkPolicy
metadata:
  name: minio-tenant
  namespace: ${var.minio_ns}
spec:
  order: 10
  selector: app.kubernetes.io/name == 'operator' || has(v1.min.io/tenant)
  types:
    - Egress
    - Ingress
  egress:
    - action: Allow
      protocol: TCP
      destination:
        selector: app.kubernetes.io/name == 'operator' || has(v1.min.io/tenant)
  ingress:
    - action: Allow
      protocol: TCP
      source:
        selector: app.kubernetes.io/name == 'operator' || has(v1.min.io/tenant)
  YAML

  depends_on = [kubernetes_namespace.minio_ns]
}

resource "kubectl_manifest" "minio_k8s_api_egress" {
  yaml_body = <<YAML
apiVersion: crd.projectcalico.org/v1
kind: NetworkPolicy
metadata:
  name: k8s-api-egress
  namespace: ${var.minio_ns}
spec:
  order: 10
  selector: app.kubernetes.io/name == 'operator' || has(v1.min.io/tenant)
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
  YAML

  depends_on = [kubernetes_namespace.minio_ns]
}

resource "kubectl_manifest" "minio_ingress" {
  yaml_body = <<YAML
apiVersion: crd.projectcalico.org/v1
kind: NetworkPolicy
metadata:
  name: minio-ingress
  namespace: ${var.minio_ns}
spec:
  order: 10
  selector: has(v1.min.io/tenant)
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
          - 9443
  YAML

  depends_on = [kubernetes_namespace.minio_ns]
}

resource "kubectl_manifest" "minio_config" {
  yaml_body = <<YAML
apiVersion: external-secrets.io/v1beta1
kind: ClusterExternalSecret
metadata:
  name: ${var.minio_config}
spec:
  externalSecretName: ${var.minio_config}
  namespaceSelectors:
    - matchLabels:
        ${var.minio_config_label.key}: "${var.minio_config_label.value}"
  refreshTime: 15s

  externalSecretSpec:
    target:
      name: ${var.minio_config}
    refreshInterval: 15s
    secretStoreRef:
      name: ${var.cluster_secret_store}
      kind: ClusterSecretStore
    data:
      - secretKey: config.env
        remoteRef:
          key: minio/config
          property: config.env
  YAML
}

module "minio_access" {
  source = "../modules/access-policy"

  namespace       = var.minio_ns
  namespace_label = var.minio_access_label
  selector        = "has(v1.min.io/tenant)"
  port            = 9000
  target_selector = "all()"

  depends_on = [kubernetes_namespace.minio_ns]
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
apiVersion: external-secrets.io/v1beta1
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
      key: minio/metrics
  YAML

  depends_on = [kubernetes_namespace.minio_ns]
}
