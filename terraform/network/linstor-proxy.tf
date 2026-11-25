
resource "kubectl_manifest" "linstor_proxy_secrets" {
  yaml_body = <<YAML
apiVersion: external-secrets.io/v1
kind: ExternalSecret
metadata:
  name: linstor-proxy
  namespace: ${var.storage_ns}
spec:
  refreshInterval: 5m
  secretStoreRef:
    name: ${var.cluster_secret_store}
    kind: ClusterSecretStore
  target:
    name: linstor-proxy
  dataFrom:
  - extract:
      key: tools/linstor-proxy
  YAML
}

resource "kubectl_manifest" "linstor_oidc_middleware" {
  yaml_body = <<YAML
apiVersion: traefik.io/v1alpha1
kind: Middleware
metadata:
  name: linstor
  namespace: ${var.storage_ns}
spec:
  plugin:
    traefik-oidc-auth:
      Secret: "urn:k8s:secret:linstor-proxy:secret"
      Provider:
        ClientId: "urn:k8s:secret:linstor-proxy:client-id"
        ClientSecret: "urn:k8s:secret:linstor-proxy:client-secret"
        Url: "https://profidev.io/api/oauth"
      Scopes:
        - "openid"
        - "profile"
        - "email"
  YAML
}

resource "kubernetes_ingress_v1" "linstor_ingress" {
  metadata {
    name      = "linstor"
    namespace = var.storage_ns

    annotations = {
      "traefik.ingress.kubernetes.io/router.middlewares"   = "${var.storage_ns}-linstor@kubernetescrd"
      "traefik.ingress.kubernetes.io/router.tls.options"   = "${var.storage_ns}-linstor-tls-options@kubernetescrd"
      "external-dns.kubernetes.io/ingress-hostname-source" = "annotation-only"
      "external-dns.kubernetes.io/cloudflare-proxied"      = "true"
      "external-dns.kubernetes.io/hostname"                = "linstor.profidev.io"
      "external-dns.kubernetes.io/target"                  = "cluster.profidev.io"
    }
  }

  spec {
    ingress_class_name = var.ingress_class
    rule {
      host = "linstor.profidev.io"
      http {
        path {
          path      = "/"
          path_type = "ImplementationSpecific"
          backend {
            service {
              name = "linstor-controller"
              port {
                name = "api"
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

resource "kubectl_manifest" "linstor_tls_options" {
  yaml_body = <<YAML
apiVersion: traefik.io/v1alpha1
kind: TLSOption
metadata:
  name: linstor-tls-options
  namespace: ${var.storage_ns}
spec:
  clientAuth:
    clientAuthType: RequireAndVerifyClientCert
    secretNames:
      - ${var.cloudflare_ca_cert_var}
  YAML
}
