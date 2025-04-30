resource "kubernetes_namespace" "stalwart_ns" {
  metadata {
    name = var.stalwart_ns
    labels = {
      "${var.postgres_access_label.key}" = var.postgres_access_label.value
      "${var.secret_store_label.key}"    = var.secret_store_label.value
    }
  }
}

resource "kubernetes_deployment_v1" "stalwart" {
  metadata {
    name      = "stalwart"
    namespace = var.stalwart_ns
  }
  spec {
    replicas = 1
    selector {
      match_labels = {
        app = "stalwart"
      }
    }
    template {
      metadata {
        labels = {
          app = "stalwart"
          "${var.postgres_access_label.key}" = var.postgres_access_label.value
        }
      }
      spec {
        container {
          name              = "stalwart"
          image             = "stalwartlabs/mail-server:latest"
          image_pull_policy = "IfNotPresent"
          liveness_probe {
            http_get {
              path = "/healthz/live"
              port = 8080
            }
            initial_delay_seconds = 30
            period_seconds        = 10
          }
          readiness_probe {
            http_get {
              path = "/healthz/ready"
              port = 8080
            }
            initial_delay_seconds = 5
            period_seconds        = 10
          }
          port {
            container_port = 8080
          }
          port {
            container_port = 25
          }
          port {
            container_port = 587
          }
          port {
            container_port = 465
          }
          port {
            container_port = 993
          }
          volume_mount {
            name       = "stalwart"
            mount_path = "/opt/stalwart-mail"
          }
        }
        volume {
          name = "stalwart"
          persistent_volume_claim {
            claim_name = "stalwart"
          }
        }
      }
    }
  }

  depends_on = [kubernetes_namespace.stalwart_ns]
}

resource "kubernetes_persistent_volume_claim_v1" "stalwart" {
  metadata {
    name      = "stalwart"
    namespace = var.stalwart_ns
  }
  spec {
    access_modes = ["ReadWriteOnce"]
    resources {
      requests = {
        storage = "20Gi"
      }
    }
    storage_class_name = var.storage_class
  }

  depends_on = [kubernetes_namespace.stalwart_ns]
}

resource "kubernetes_service_v1" "stalwart" {
  metadata {
    name      = "stalwart"
    namespace = var.stalwart_ns
    labels = {
      "app" = "stalwart"
    }
  }
  spec {
    type = "ClusterIP"
    port {
      name        = "http"
      port        = 8080
      target_port = 8080
    }
    port {
      name        = "smtp"
      port        = 25
      target_port = 25
    }
    port {
      name        = "submission"
      port        = 587
      target_port = 587
    }
    port {
      name        = "smtps"
      port        = 465
      target_port = 465
    }
    port {
      name        = "imaps"
      port        = 993
      target_port = 993
    }

    selector = {
      app = "stalwart"
    }
  }

  depends_on = [kubernetes_namespace.stalwart_ns]
}

resource "kubernetes_ingress_v1" "stalwart" {
  metadata {
    name = "stalwart"
    annotations = {
      "cert-manager.io/cluster-issuer" = var.cert_issuer_prod
    }
    namespace = var.stalwart_ns
  }

  spec {
    ingress_class_name = var.ingress_class
    rule {
      host = "mail.profidev.io"
      http {
        path {
          backend {
            service {
              name = "stalwart"
              port {
                number = 8080
              }
            }
          }
          path      = "/"
          path_type = "Prefix"
        }
      }
    }
    rule {
      host = "autodiscover.profidev.io"
      http {
        path {
          backend {
            service {
              name = "stalwart"
              port {
                number = 8080
              }
            }
          }
          path      = "/"
          path_type = "Prefix"
        }
      }
    }
    rule {
      host = "autoconfig.profidev.io"
      http {
        path {
          backend {
            service {
              name = "stalwart"
              port {
                number = 8080
              }
            }
          }
          path      = "/"
          path_type = "Prefix"
        }
      }
    }
    rule {
      host = "mta-sts.profidev.io"
      http {
        path {
          backend {
            service {
              name = "stalwart"
              port {
                number = 8080
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
        "mail.profidev.io",
        "autodiscover.profidev.io",
        "autoconfig.profidev.io",
        "mta-sts.profidev.io",
      ]
      secret_name = "stalwart-tls"
    }
  }

  depends_on = [kubernetes_namespace.positron_ns]
}

resource "kubectl_manifest" "stalwart_egress" {
  yaml_body = <<YAML
apiVersion: crd.projectcalico.org/v1
kind: GlobalNetworkPolicy
metadata:
  name: stalwart-egress
spec:
  namespaceSelector: kubernetes.io/metadata.name == '${var.stalwart_ns}'
  selector: app == 'stalwart'
  types:
    - Egress
  egress:
    - action: Allow
      protocol: TCP
      destination:
        ports:
          - 443
          - 25
  YAML

  depends_on = [kubernetes_namespace.stalwart_ns]
}

resource "kubectl_manifest" "stalwart_metrics" {
  yaml_body = <<YAML
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: stalwart
  namespace: ${var.stalwart_ns}
spec:
  selector:
    matchLabels:
      app: stalwart
  endpoints:
    - port: http
      interval: 60s
      path: "/metrics/prometheus"
      basicAuth:
        username:
          name: stalwart
          key: METRICS_USERNAME
        password:
          name: stalwart
          key: METRICS_SECRET
      metricRelabelings:
        - sourceLabels: [__name__]
          targetLabel: __name__
          replacement: stalwart_$1
  YAML

  depends_on = [kubernetes_namespace.stalwart_ns]
}

resource "kubectl_manifest" "stalwart_secret" {
  yaml_body = <<YAML
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: stalwart
  namespace: ${var.stalwart_ns}
spec:
  refreshInterval: 15s
  secretStoreRef:
    name: ${var.cluster_secret_store}
    kind: ClusterSecretStore
  target:
    name: stalwart
  dataFrom:
  - extract:
      key: apps/stalwart
  YAML

  depends_on = [kubernetes_namespace.stalwart_ns]
}
