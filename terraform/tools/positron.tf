resource "kubernetes_namespace" "positron_ns" {
  metadata {
    name = var.positron_ns
    labels = {
      "${var.cloudflare_cert_label.key}" = var.cloudflare_cert_label.value
      "${var.secret_store_label.key}"    = var.secret_store_label.value
      "${var.cluster_ca_cert_label.key}" = var.cluster_ca_cert_label.value
      "${var.minio_access_label.key}"    = var.minio_access_label.value
      "${var.postgres_access_label.key}" = var.postgres_access_label.value
      "${var.nats_access_label.key}"     = var.nats_access_label.value
    }
  }
}

resource "kubectl_manifest" "positron_secrets" {
  yaml_body = <<YAML
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: positron-backend
  namespace: ${var.positron_ns}
spec:
  refreshInterval: 15s
  secretStoreRef:
    name: ${var.cluster_secret_store}
    kind: ClusterSecretStore
  target:
    name: positron-backend
  dataFrom:
  - extract:
      key: apps/positron
  YAML

  depends_on = [kubernetes_namespace.positron_ns]
}

resource "kubectl_manifest" "positron_minio" {
  yaml_body = <<YAML
apiVersion: crd.projectcalico.org/v1
kind: NetworkPolicy
metadata:
  name: positron-backend-minio
  namespace: ${var.positron_ns}
spec:
  order: 10
  selector: app == 'positron-backend'
  types:
    - Egress
  egress:
    - action: Allow
      protocol: TCP
      destination:
        namespaceSelector: kubernetes.io/metadata.name == '${var.minio_ns}'
        selector: has(v1.min.io/tenant)
        ports:
        - 9000
  YAML

  depends_on = [kubernetes_namespace.positron_ns]
}

resource "kubectl_manifest" "positron_postgres" {
  yaml_body = <<YAML
apiVersion: crd.projectcalico.org/v1
kind: NetworkPolicy
metadata:
  name: positron-backend-db
  namespace: ${var.positron_ns}
spec:
  order: 10
  selector: app == 'positron-backend'
  types:
    - Egress
  egress:
    - action: Allow
      protocol: TCP
      destination:
        namespaceSelector: kubernetes.io/metadata.name == '${var.everest_ns}'
        selector: app.kubernetes.io/name == 'percona-postgresql'
        ports:
          - 5432
  YAML

  depends_on = [kubernetes_namespace.positron_ns]
}

resource "kubectl_manifest" "positron_backend_ingress" {
  yaml_body = <<YAML
apiVersion: crd.projectcalico.org/v1
kind: NetworkPolicy
metadata:
  name: positron-backend-ingress
  namespace: ${var.positron_ns}
spec:
  order: 10
  selector: app == 'positron-backend'
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

  depends_on = [kubernetes_namespace.positron_ns]
}

resource "kubectl_manifest" "positron_frontend_ingress" {
  yaml_body = <<YAML
apiVersion: crd.projectcalico.org/v1
kind: NetworkPolicy
metadata:
  name: positron-frontend-ingress
  namespace: ${var.positron_ns}
spec:
  order: 10
  selector: app == 'positron-frontend'
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
          - 3000
  YAML

  depends_on = [kubernetes_namespace.positron_ns]
}

resource "kubectl_manifest" "positron_egress" {
  yaml_body = <<YAML
apiVersion: crd.projectcalico.org/v1
kind: GlobalNetworkPolicy
metadata:
  name: positron-egress
spec:
  namespaceSelector: kubernetes.io/metadata.name == '${var.positron_ns}'
  selector: app == 'positron-backend'
  types:
    - Egress
  egress:
    - action: Allow
      protocol: TCP
      destination:
        ports:
          - 443
        domains:
          - api.nasa.gov
  YAML

  depends_on = [kubernetes_namespace.positron_ns]
}

resource "kubectl_manifest" "oidc_access" {
  yaml_body = <<YAML
apiVersion: crd.projectcalico.org/v1
kind: NetworkPolicy
metadata:
  name: oidc-access
  namespace: ${var.positron_ns}
spec:
  order: 10
  namespaceSelector: kubernetes.io/metadata.name == '${var.positron_ns}'
  selector: app == 'positron-backend'
  types:
    - Ingress
  ingress:
    - action: Allow
      protocol: TCP
      source:
        namespaceSelector: ${var.oidc_access_label.key} == '${var.oidc_access_label.value}'
      destination:
        ports:
        - 8000
  YAML

  depends_on = [kubernetes_namespace.positron_ns]
}

resource "kubernetes_ingress_v1" "positron_frontend" {
  metadata {
    name = "positron-frontend"
    annotations = {
      "nginx.ingress.kubernetes.io/auth-tls-secret"        = "${var.positron_ns}/${var.cloudflare_ca_cert_var}",
      "nginx.ingress.kubernetes.io/auth-tls-verify-client" = "on"
    }
    namespace = var.positron_ns
  }

  spec {
    ingress_class_name = var.ingress_class
    rule {
      host = "profidev.io"
      http {
        path {
          backend {
            service {
              name = "positron-frontend"
              port {
                number = 3000
              }
            }
          }
          path      = "/"
          path_type = "Prefix"
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

  depends_on = [kubernetes_namespace.positron_ns]
}

resource "kubernetes_ingress_v1" "positron_backend" {
  metadata {
    name = "positron-backend"
    annotations = {
      "nginx.ingress.kubernetes.io/auth-tls-secret"        = "${var.positron_ns}/${var.cloudflare_ca_cert_var}",
      "nginx.ingress.kubernetes.io/auth-tls-verify-client" = "on",
      "nginx.ingress.kubernetes.io/rewrite-target"         = "/$1"
    }
    namespace = var.positron_ns
  }

  spec {
    ingress_class_name = var.ingress_class
    rule {
      host = "profidev.io"
      http {
        path {
          backend {
            service {
              name = "positron-backend"
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

  depends_on = [kubernetes_namespace.positron_ns]
}
