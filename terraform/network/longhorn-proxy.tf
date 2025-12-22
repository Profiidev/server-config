
resource "kubectl_manifest" "longhorn_proxy_secrets" {
  yaml_body = <<YAML
apiVersion: external-secrets.io/v1
kind: ExternalSecret
metadata:
  name: longhorn-proxy
  namespace: ${var.storage_ns}
spec:
  refreshInterval: 5m
  secretStoreRef:
    name: ${var.cluster_secret_store}
    kind: ClusterSecretStore
  target:
    name: longhorn-proxy
  dataFrom:
  - extract:
      key: tools/longhorn-proxy
  YAML
}

resource "kubectl_manifest" "longhorn_oidc_middleware" {
  yaml_body = <<YAML
apiVersion: traefik.io/v1alpha1
kind: Middleware
metadata:
  name: longhorn
  namespace: ${var.storage_ns}
spec:
  plugin:
    traefik-oidc-auth:
      Secret: "urn:k8s:secret:longhorn-proxy:secret"
      Provider:
        ClientId: "urn:k8s:secret:longhorn-proxy:client-id"
        ClientSecret: "urn:k8s:secret:longhorn-proxy:client-secret"
        Url: "https://profidev.io/backend/oauth"
      Scopes:
        - "openid"
        - "profile"
        - "email"
  YAML
}

resource "kubernetes_ingress_v1" "longhorn_ingress" {
  metadata {
    name      = "longhorn"
    namespace = var.storage_ns

    annotations = {
      "traefik.ingress.kubernetes.io/router.middlewares" = "${var.storage_ns}-longhorn@kubernetescrd"
      "traefik.ingress.kubernetes.io/router.tls.options" = "${var.storage_ns}-longhorn-tls-options@kubernetescrd"
    }
  }

  spec {
    ingress_class_name = var.ingress_class
    rule {
      host = "longhorn.profidev.io"
      http {
        path {
          path      = "/"
          path_type = "ImplementationSpecific"
          backend {
            service {
              name = "longhorn-frontend"
              port {
                name = "http"
              }
            }
          }
        }
      }
    }

    tls {
      secret_name = var.cloudflare_cert_var
      hosts = [
        "*.profidev.io",
        "profidev.io"
      ]
    }
  }
}

resource "kubectl_manifest" "longhorn_tls_options" {
  yaml_body = <<YAML
apiVersion: traefik.io/v1alpha1
kind: TLSOption
metadata:
  name: longhorn-tls-options
  namespace: ${var.storage_ns}
spec:
  clientAuth:
    clientAuthType: RequireAndVerifyClientCert
    secretNames:
      - ${var.cloudflare_ca_cert_var}
  YAML
}
