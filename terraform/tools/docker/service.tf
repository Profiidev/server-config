resource "kubernetes_ingress_v1" "ingress" {
  metadata {
    name      = var.name
    namespace = var.namespace
    annotations = var.cloudflare ? {
      "nginx.ingress.kubernetes.io/auth-tls-secret"        = "${var.namespace}/${var.cloudflare_ca_cert_var}",
      "nginx.ingress.kubernetes.io/auth-tls-verify-client" = "on"
      } : {
      "cert-manager.io/cluster-issuer" = var.cert_issuer
    }
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

resource "kubectl_manifest" "networkpolicy" {
  yaml_body = <<YAML
apiVersion: crd.projectcalico.org/v1
kind: NetworkPolicy
metadata:
  name: ${var.name}
  namespace: ${var.namespace}
spec:
  order: 10
  selector: app.kubernetes.io/name == '${var.name}'
  types:
    - Ingress
    - Egress
  ingress:
    - action: Allow
      protocol: TCP
      source:
        namespaceSelector: kubernetes.io/metadata.name == 'kube-system'
        selector: app.kubernetes.io/name == 'rke2-ingress-nginx'
      destination:
        ports:
          - ${var.port}
  egress:
    - action: Allow
      protocol: TCP
  YAML
}
