resource "helm_release" "alloy" {
  name       = "alloy"
  repository = "https://grafana.github.io/helm-charts"
  chart      = "alloy"
  version    = "1.4.0"
  namespace  = var.metrics_ns

  values = [templatefile("${path.module}/templates/alloy.values.tftpl", {
    ca_hash = local.ca_hash
  })]
}

resource "kubectl_manifest" "alloy_proxy_secrets" {
  yaml_body = <<YAML
apiVersion: external-secrets.io/v1
kind: ExternalSecret
metadata:
  name: alloy-proxy
  namespace: ${var.metrics_ns}
spec:
  refreshInterval: 15s
  secretStoreRef:
    name: ${var.cluster_secret_store}
    kind: ClusterSecretStore
  target:
    name: alloy-proxy
  dataFrom:
  - extract:
      key: apps/alloy-proxy
  YAML
}

resource "kubectl_manifest" "alloy_oidc_middleware" {
  yaml_body = <<YAML
apiVersion: traefik.io/v1alpha1
kind: Middleware
metadata:
  name: alloy
  namespace: ${var.metrics_ns}
spec:
  plugin:
    traefik-oidc-auth:
      Secret: "urn:k8s:secret:alloy-proxy:secret"
      Provider:
        ClientId: "urn:k8s:secret:alloy-proxy:client-id"
        ClientSecret: "urn:k8s:secret:alloy-proxy:client-secret"
        Url: "https://profidev.io/backend/oauth"
      Scopes:
        - "openid"
        - "profile"
        - "email"
  YAML
}

resource "kubernetes_ingress_v1" "alloy_ingress" {
  metadata {
    name      = "alloy"
    namespace = var.metrics_ns

    annotations = {
      "traefik.ingress.kubernetes.io/router.middlewares"   = "${var.metrics_ns}-alloy@kubernetescrd"
      "traefik.ingress.kubernetes.io/router.tls.options" = "${var.metrics_ns}-alloy-tls-options@kubernetescrd"
    }
  }

  spec {
    ingress_class_name = var.ingress_class
    rule {
      host = "alloy.profidev.io"
      http {
        path {
          path      = "/"
          path_type = "ImplementationSpecific"
          backend {
            service {
              name = "alloy"
              port {
                name = "http-metrics"
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

resource "kubectl_manifest" "alloy_tls_options" {
  yaml_body = <<YAML
apiVersion: traefik.io/v1alpha1
kind: TLSOption
metadata:
  name: alloy-tls-options
  namespace: ${var.metrics_ns}
spec:
  clientAuth:
    clientAuthType: RequireAndVerifyClientCert
    secretNames:
      - ${var.cloudflare_ca_cert_var}
  YAML
}

