resource "kubernetes_ingress_v1" "ingress" {
  metadata {
    name      = var.name
    namespace = var.namespace
    annotations = merge(var.cloudflare ? {
      "traefik.ingress.kubernetes.io/router.tls.options" = "${var.namespace}-${var.name}-tls-options@kubernetescrd"
      } : {
      "cert-manager.io/cluster-issuer" = var.cert_issuer
      }, var.https ? {
      "nginx.ingress.kubernetes.io/backend-protocol" = "HTTPS"
    } : {}, var.annotations)
  }

  spec {
    ingress_class_name = var.ingress_class
    rule {
      host = var.domain
      http {
        path {
          backend {
            service {
              name = var.name
              port {
                number = var.port
              }
            }
          }
          path      = "/"
          path_type = "Prefix"
        }
      }
    }

    tls {
      hosts       = var.cloudflare ? ["*.profidev.io", "profidev.io"] : [var.domain]
      secret_name = var.cloudflare ? var.cloudflare_cert_var : "${var.name}-tls"
    }
  }
}

resource "kubectl_manifest" "tls_options" {
  yaml_body = <<YAML
apiVersion: traefik.io/v1alpha1
kind: TLSOption
metadata:
  name: ${var.name}-tls-options
  namespace: ${var.namespace}
spec:
  clientAuth:
    clientAuthType: RequireAndVerifyClientCert
    secretNames:
      - ${var.cloudflare_ca_cert_var}
  YAML
}

resource "kubernetes_service_v1" "service" {
  metadata {
    name      = var.name
    namespace = var.namespace
    labels = {
      "app.kubernetes.io/name" = var.name
    }
  }
  spec {
    port {
      port        = var.port
      target_port = var.port
      protocol    = "TCP"
    }
  }
}

resource "kubernetes_endpoints_v1" "endpoint" {
  metadata {
    name      = var.name
    namespace = var.namespace
  }
  subset {
    address {
      ip = var.ip
    }
    port {
      port = var.port
    }
  }
}
