resource "kubernetes_namespace" "crowdsec" {
  metadata {
    name = var.crowdsec_ns
  }
}

resource "random_password" "bouncer_key" {
  min_lower   = 1
  min_upper   = 1
  min_numeric = 1
  special     = false
  length      = 32
}

resource "helm_release" "crowdsec" {
  name       = "crowdsec"
  repository = "https://crowdsecurity.github.io/helm-charts"
  chart      = "crowdsec"
  namespace  = var.crowdsec_ns
  version    = "0.24.0"

  values = [
    templatefile("${path.module}/templates/crowdsec.values.tftpl", {
      traefik_bouncer_key = random_password.bouncer_key.result
    })
  ]

  depends_on = [kubernetes_namespace.crowdsec]
}

resource "kubectl_manifest" "crowdsec_secrets" {
  yaml_body = <<YAML
apiVersion: external-secrets.io/v1
kind: ExternalSecret
metadata:
  name: crowdsec
  namespace: ${var.crowdsec_ns}
spec:
  refreshInterval: 5m
  secretStoreRef:
    name: ${var.cluster_secret_store}
    kind: ClusterSecretStore
  target:
    name: crowdsec
  dataFrom:
  - extract:
      key: certs/crowdsec
  YAML

  depends_on = [kubernetes_namespace.crowdsec]
}

module "external_np_crowdsec" {
  source = "../modules/external-np"

  namespace = var.crowdsec_ns

  depends_on = [kubernetes_namespace.crowdsec]
}

resource "helm_release" "crowdsec_web_ui" {
  name       = "crowdsec-web-ui"
  repository = "https://zekker6.github.io/helm-charts"
  chart      = "crowdsec-web-ui"
  namespace  = var.crowdsec_ns
  version    = "0.34.0"

  values = [
    templatefile("${path.module}/templates/crowdsec-web-ui.values.tftpl", {
      ingress_class   = var.ingress_class
      namespace       = var.crowdsec_ns
      cloudflare_cert = var.cloudflare_cert_var
    })
  ]

  depends_on = [kubernetes_namespace.crowdsec]
}

resource "kubectl_manifest" "crowdsec_proxy_secrets" {
  yaml_body = <<YAML
apiVersion: external-secrets.io/v1
kind: ExternalSecret
metadata:
  name: crowdsec-proxy
  namespace: ${var.crowdsec_ns}
spec:
  refreshInterval: 5m
  secretStoreRef:
    name: ${var.cluster_secret_store}
    kind: ClusterSecretStore
  target:
    name: crowdsec-proxy
  dataFrom:
  - extract:
      key: tools/crowdsec-proxy
  YAML
}

resource "kubectl_manifest" "crowdsec_oidc_middleware" {
  yaml_body = <<YAML
apiVersion: traefik.io/v1alpha1
kind: Middleware
metadata:
  name: crowdsec
  namespace: ${var.crowdsec_ns}
spec:
  plugin:
    traefik-oidc-auth:
      Secret: "urn:k8s:secret:crowdsec-proxy:secret"
      Provider:
        ClientId: "urn:k8s:secret:crowdsec-proxy:client-id"
        ClientSecret: "urn:k8s:secret:crowdsec-proxy:client-secret"
        Url: "https://profidev.io/api/oauth"
      Scopes:
        - "openid"
        - "profile"
        - "email"
  YAML
}

resource "kubectl_manifest" "crowdsec_tls_options" {
  yaml_body = <<YAML
apiVersion: traefik.io/v1alpha1
kind: TLSOption
metadata:
  name: crowdsec-tls-options
  namespace: ${var.crowdsec_ns}
spec:
  clientAuth:
    clientAuthType: RequireAndVerifyClientCert
    secretNames:
      - ${var.cloudflare_ca_cert_var}
  YAML
}
