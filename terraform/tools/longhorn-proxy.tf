resource "helm_release" "longhorn_oauth2_proxy" {
  name       = "longhorn-oauth2-proxy"
  repository = "https://oauth2-proxy.github.io/manifests"
  chart      = "oauth2-proxy"
  version    = "7.12.9"
  namespace  = var.storage_ns

  values = [templatefile("${path.module}/templates/longhorn-oauth2-proxy.values.tftpl", {
    namespace              = var.storage_ns
    ingress_class          = var.ingress_class
    cloudflare_ca_cert_var = var.cloudflare_ca_cert_var
    cloudflare_cert_var    = var.cloudflare_cert_var
  })]

  depends_on = [kubernetes_namespace.storage_ns]
}

resource "kubectl_manifest" "longhorn_proxy_secrets" {
  yaml_body = <<YAML
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: longhorn-proxy
  namespace: ${var.storage_ns}
spec:
  refreshInterval: 15s
  secretStoreRef:
    name: ${var.cluster_secret_store}
    kind: ClusterSecretStore
  target:
    name: longhorn-proxy
  dataFrom:
  - extract:
      key: apps/longhorn-proxy
  YAML

  depends_on = [kubernetes_namespace.storage_ns]
}

resource "kubectl_manifest" "longhorn_secret" {
  yaml_body = <<YAML
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: longhorn-secret
  namespace: ${var.storage_ns}
spec:
  refreshInterval: 15s
  secretStoreRef:
    name: ${var.cluster_secret_store}
    kind: ClusterSecretStore
  target:
    name: longhorn-secret
  dataFrom:
  - extract:
      key: apps/longhorn
  YAML

  depends_on = [kubernetes_namespace.storage_ns]
}
