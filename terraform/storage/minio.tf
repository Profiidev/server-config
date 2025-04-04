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

resource "kubectl_manifest" "minio_access" {
  yaml_body = <<YAML
apiVersion: crd.projectcalico.org/v1
kind: NetworkPolicy
metadata:
  name: minio-access
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
        namespaceSelector: ${var.minio_access_label.key} == '${var.minio_access_label.value}'
      destination:
        ports:
        - 9000
  YAML

  depends_on = [kubernetes_namespace.minio_ns]
}

resource "kubectl_manifest" "portainer_oidc" {
  yaml_body = <<YAML
apiVersion: crd.projectcalico.org/v1
kind: NetworkPolicy
metadata:
  name: minio-oidc
  namespace: ${var.minio_ns}
spec:
  order: 10
  selector: has(v1.min.io/tenant)
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

  depends_on = [kubernetes_namespace.minio_ns]
}
