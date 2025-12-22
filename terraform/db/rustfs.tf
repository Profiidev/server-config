resource "kubernetes_namespace" "rustfs" {
  metadata {
    name = var.rustfs_ns
  }
}

resource "kubectl_manifest" "rustfs_secret" {
  yaml_body = <<YAML
apiVersion: external-secrets.io/v1
kind: ExternalSecret
metadata:
  name: rustfs
  namespace: ${var.rustfs_ns}
spec:
  refreshInterval: 5m
  secretStoreRef:
    name: ${var.cluster_secret_store}
    kind: ClusterSecretStore
  target:
    name: rustfs-secret
  dataFrom:
  - extract:
      key: db/rustfs
  YAML

  depends_on = [kubernetes_namespace.rustfs]
}

resource "kubernetes_config_map_v1" "rustfs-config" {
  metadata {
    name      = "rustfs-config"
    namespace = var.rustfs_ns
  }

  data = {
    "RUSTFS_ADDRESS"           = "0.0.0.0:9000",
    "RUSTFS_CONSOLE_ADDRESS"   = "0.0.0.0:9001",
    "RUSTFS_OBS_LOG_DIRECTORY" = "/logs",
    "RUSTFS_CONSOLE_ENABLE"    = "true",
    "RUSTFS_OBS_LOGGER_LEVEL"  = "debug",
    "RUSTFS_VOLUMES"           = "/data",
    "RUSTFS_OBS_ENVIRONMENT"   = "develop",
    "RUSTFS_BUFFER_PROFILE"    = "SecureStorage"
  }

  depends_on = [kubernetes_namespace.rustfs]
}

resource "kubernetes_persistent_volume_claim_v1" "rustfs_data" {
  metadata {
    name      = "rustfs-data"
    namespace = var.rustfs_ns
  }

  spec {
    access_modes       = ["ReadWriteOnce"]
    storage_class_name = var.storage_class
    resources {
      requests = {
        "storage" = "200Gi"
      }
    }
  }
  depends_on = [kubernetes_namespace.rustfs]
}

resource "kubernetes_persistent_volume_claim_v1" "rustfs_logs" {
  metadata {
    name      = "rustfs-logs"
    namespace = var.rustfs_ns
  }

  spec {
    access_modes       = ["ReadWriteOnce"]
    storage_class_name = var.storage_class
    resources {
      requests = {
        "storage" = "10Gi"
      }
    }
  }
}

resource "kubernetes_deployment_v1" "rustfs" {
  metadata {
    labels = {
      "app" = "rustfs",
    }
    name      = "rustfs"
    namespace = var.rustfs_ns
  }

  spec {
    progress_deadline_seconds = 600
    replicas                  = 1
    revision_history_limit    = 10
    selector {
      match_labels = {
        "app" = "rustfs"
      }
    }

    strategy {
      rolling_update {
        max_surge       = "25%"
        max_unavailable = "25%"
      }
    }

    template {
      metadata {
        labels = {
          "app" = "rustfs"
        }
      }

      spec {
        container {
          command = ["/usr/bin/rustfs"]
          env_from {
            config_map_ref {
              name = "rustfs-config"
            }
          }
          env_from {
            secret_ref {
              name = "rustfs-secret"
            }
          }
          image             = "rustfs/rustfs:1.0.0-alpha.70"
          image_pull_policy = "IfNotPresent"
          liveness_probe {
            failure_threshold = 3
            http_get {
              path   = "/health"
              port   = 9000
              scheme = "HTTP"
            }
            initial_delay_seconds = 10
            period_seconds        = 5
            success_threshold     = 1
            timeout_seconds       = 3
          }
          name = "rustfs"
          port {
            container_port = 9000
            name           = "endpoint"
            protocol       = "TCP"
          }

          port {
            container_port = 9001
            name           = "console"
            protocol       = "TCP"
          }

          readiness_probe {
            failure_threshold = 3
            http_get {
              path   = "/health"
              port   = 9000
              scheme = "HTTP"
            }
            initial_delay_seconds = 10
            period_seconds        = 5
            success_threshold     = 1
            timeout_seconds       = 3
          }

          resources {
            limits = {
              "cpu" : "1"
              "memory" : "4Gi"
            }
            requests = {
              "cpu" : "100m"
              "memory" : "512Mi"
            }
          }
          security_context {
            capabilities {
              drop = ["ALL"]
            }
            read_only_root_filesystem = false
            run_as_non_root           = true
          }

          termination_message_path   = "/dev/termination-log"
          termination_message_policy = "File"
          volume_mount {
            mount_path = "/data"
            name       = "data"
          }
          volume_mount {
            name       = "logs"
            mount_path = "/logs"
          }
        }
        dns_policy = "ClusterFirst"
        init_container {
          command = [
            "sh",
            "-c",
            <<-EOF
            mkdir -p /data /logs
            chown -R 10001:10001 /data /logs
            EOF
            ,
          ]
          image             = "busybox"
          image_pull_policy = "IfNotPresent"
          name              = "init-step"
          resources {

          }
          security_context {
            run_as_group = 0
            run_as_user  = 0
          }
          termination_message_path   = "/dev/termination-log"
          termination_message_policy = "File"
          volume_mount {
            mount_path = "/data"
            name       = "data"
          }
          volume_mount {
            name       = "logs"
            mount_path = "/logs"
          }
        }
        restart_policy = "Always"
        scheduler_name = "default-scheduler"
        security_context {
          fs_group     = 10001
          run_as_group = 10001
          run_as_user  = 10001
        }
        termination_grace_period_seconds = 30
        volume {
          name = "logs"
          persistent_volume_claim {
            claim_name = "rustfs-logs"
          }
        }
        volume {
          name = "data"
          persistent_volume_claim {
            claim_name = "rustfs-data"
          }
        }
      }
    }
  }

  depends_on = [
    kubernetes_persistent_volume_claim_v1.rustfs_data,
    kubernetes_persistent_volume_claim_v1.rustfs_logs,
    kubernetes_namespace.rustfs,
    kubernetes_config_map_v1.rustfs-config,
    kubectl_manifest.rustfs_secret,
  ]
}

resource "kubernetes_service_v1" "rustfs" {
  metadata {
    name      = "rustfs-svc"
    namespace = var.rustfs_ns
    labels = {
      "app.kubernetes.io/name"     = "rustfs",
      "app.kubernetes.io/instance" = "rustfs"
    }
  }
  spec {
    type = "ClusterIP"
    port {
      port        = 9000
      target_port = 9000
      protocol    = "TCP"
      name        = "endpoint"
    }
    port {
      port        = 9001
      target_port = 9001
      protocol    = "TCP"
      name        = "console"
    }
    selector = {
      "app" = "rustfs"
    }
  }

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
  depends_on = [kubernetes_namespace.rustfs]
}
