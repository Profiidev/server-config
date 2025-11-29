resource "kubernetes_namespace" "rustfs" {
  metadata {
    name = var.rustfs_ns
  }
}

resource "helm_release" "minio" {
  name       = "rustfs"
  repository = "https://charts.rustfs.com"
  chart      = "rustfs"
  version    = "0.0.68"
  namespace  = var.rustfs_ns

  values = [templatefile("${path.module}/templates/rustfs.values.tftpl", {
    storage_class = var.storage_class
    ingress_class = var.ingress_class
    cert_issuer   = var.cert_issuer_prod
    password      = var.rustfs_password
  })]

  depends_on = [kubernetes_namespace.rustfs]
}

resource "kubernetes_ingress_v1" "rustfs" {
  metadata {
    name      = "rustfs"
    namespace = var.rustfs_ns
    annotations = {
      "cert-manager.io/cluster-issuer"                               = var.cert_issuer_prod,
      "traefik.ingress.kubernetes.io/service.sticky.cookie"          = "true",
      "traefik.ingress.kubernetes.io/service.sticky.cookie.httponly" = "true",
      "traefik.ingress.kubernetes.io/service.sticky.cookie.name"     = "rustfs",
      "traefik.ingress.kubernetes.io/service.sticky.cookie.samesite" = "none",
      "traefik.ingress.kubernetes.io/service.sticky.cookie.secure"   = "true",
    }
  }

  spec {
    ingress_class_name = var.ingress_class

    rule {
      host = "rustfs.profidev.io"

      http {
        path {
          path      = "/"
          path_type = "ImplementationSpecific"

          backend {
            service {
              name = "rustfs-svc"
              port {
                name = "console"
              }
            }
          }
        }
      }
    }

    tls {
      hosts       = ["rustfs.profidev.io"]
      secret_name = "rustfs-tls"
    }
  }
}
