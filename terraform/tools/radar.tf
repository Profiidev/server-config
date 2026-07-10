resource "kubernetes_namespace" "radar" {
  metadata {
    name = var.radar_ns
  }
}

resource "helm_release" "radar" {
  name       = "radar"
  repository = "https://skyhook-io.github.io/helm-charts"
  chart      = "radar"
  version    = "1.5.10"
  namespace  = var.radar_ns

  values = [templatefile("${path.module}/templates/radar.values.tftpl", {
    ingress_class       = var.ingress_class
    cloudflare_cert_var = var.cloudflare_cert_var
    namespace           = var.radar_ns
  })]

  depends_on = [kubernetes_namespace.radar]
}

resource "kubectl_manifest" "radar_secrets" {
  yaml_body = <<YAML
apiVersion: external-secrets.io/v1
kind: ExternalSecret
metadata:
  name: radar
  namespace: ${var.radar_ns}
spec:
  refreshInterval: 5m
  secretStoreRef:
    name: ${var.cluster_secret_store}
    kind: ClusterSecretStore
  target:
    name: radar
  dataFrom:
  - extract:
      key: tools/radar
  YAML

  depends_on = [kubernetes_namespace.radar]
}

resource "kubectl_manifest" "radar_oidc_middleware" {
  yaml_body = <<YAML
apiVersion: traefik.io/v1alpha1
kind: Middleware
metadata:
  name: radar
  namespace: ${var.radar_ns}
spec:
  plugin:
    traefik-oidc-auth:
      Secret: "urn:k8s:secret:radar:secret"
      Provider:
        ClientId: "urn:k8s:secret:radar:client-id"
        ClientSecret: "urn:k8s:secret:radar:client-secret"
        Url: "https://profidev.io/api/oauth"
      Scopes:
        - "openid"
        - "profile"
        - "email"
  YAML

  depends_on = [kubernetes_namespace.radar]
}

resource "kubectl_manifest" "radar_tls_options" {
  yaml_body = <<YAML
apiVersion: traefik.io/v1alpha1
kind: TLSOption
metadata:
  name: radar-tls-options
  namespace: ${var.radar_ns}
spec:
  clientAuth:
    clientAuthType: RequireAndVerifyClientCert
    secretNames:
      - ${var.cloudflare_ca_cert_var}
  YAML

  depends_on = [kubernetes_namespace.radar]
}
