resource "kubernetes_namespace" "proton_ns" {
  metadata {
    name = var.proton_ns
    labels = {
      "${var.cloudflare_cert_label.key}" = var.cloudflare_cert_label.value
      "${var.secret_store_label.key}"    = var.secret_store_label.value
      "${var.cluster_ca_cert_label.key}" = var.cluster_ca_cert_label.value
    }
  }
}

resource "kubectl_manifest" "proton_secrets" {
  yaml_body = <<YAML
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: proton-backend
  namespace: ${var.proton_ns}
spec:
  refreshInterval: 15s
  secretStoreRef:
    name: ${var.cluster_secret_store}
    kind: ClusterSecretStore
  target:
    name: proton-backend
  dataFrom:
  - extract:
      key: apps/proton
  YAML

  depends_on = [kubernetes_namespace.proton_ns]
}

resource "kubectl_manifest" "proton_backend_ingress" {
  yaml_body = <<YAML
apiVersion: crd.projectcalico.org/v1
kind: NetworkPolicy
metadata:
  name: proton-backend-ingress
  namespace: ${var.proton_ns}
spec:
  order: 10
  selector: app == 'proton-backend'
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
          - 8000
  YAML

  depends_on = [kubernetes_namespace.proton_ns]
}

resource "kubernetes_ingress_v1" "proton_backend" {
  metadata {
    name = "proton-backend"
    annotations = {
      "nginx.ingress.kubernetes.io/auth-tls-secret"        = "${var.proton_ns}/${var.cloudflare_ca_cert_var}",
      "nginx.ingress.kubernetes.io/auth-tls-verify-client" = "on",
      "nginx.ingress.kubernetes.io/rewrite-target"         = "/$1"
    }
    namespace = var.proton_ns
  }

  spec {
    ingress_class_name = var.ingress_class
    rule {
      host = "proton.profidev.io"
      http {
        path {
          backend {
            service {
              name = "proton-backend"
              port {
                number = 8000
              }
            }
          }
          path      = "/backend(.*)"
          path_type = "ImplementationSpecific"
        }
      }
    }
    tls {
      hosts = [
        "profidev.io",
        "*.profidev.io"
      ]
      secret_name = var.cloudflare_cert_var
    }
  }

  depends_on = [kubernetes_namespace.proton_ns]
}
