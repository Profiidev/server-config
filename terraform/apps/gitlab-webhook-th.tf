resource "kubernetes_namespace" "gitlab_webhook_th" {
  metadata {
    name = var.gitlab_webhook_th_ns
  }
}

resource "kubectl_manifest" "gitlab_webhook_th_secret" {
  yaml_body = <<YAML
apiVersion: external-secrets.io/v1
kind: ExternalSecret
metadata:
  name: gitlab-webhook-th
  namespace: ${var.gitlab_webhook_th_ns}
spec:
  refreshInterval: 5m
  secretStoreRef:
    name: ${var.cluster_secret_store}
    kind: ClusterSecretStore
  target:
    name: gitlab-webhook-th
  dataFrom:
  - extract:
      key: apps/gitlab-webhook-th
  YAML

  depends_on = [kubernetes_namespace.gitlab_webhook_th]
}

resource "kubernetes_deployment_v1" "gitlab_webhook_th" {
  metadata {
    name      = "gitlab-webhook-th"
    namespace = var.gitlab_webhook_th_ns
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        "app" = "gitlab-webhook-th"
      }
    }

    template {
      metadata {
        labels = {
          "app" = "gitlab-webhook-th"
        }
      }

      spec {
        container {
          name              = "bot"
          image             = "ghcr.io/realmikechong/claude-code-gitlab-app:latest@sha256:92a0bdc534cc86f09051d04dba3da6d6cbabf1f7608064a3df4e12df17439acd"
          image_pull_policy = "IfNotPresent"

          env_from {
            secret_ref {
              name = "gitlab-webhook-th"
            }
          }

          env {
            name  = "REDIS_URL"
            value = "redis://localhost:6379"
          }

          port {
            container_port = 3000
          }

          readiness_probe {
            http_get {
              path = "/health"
              port = 3000
            }
          }
        }

        # ponytail: ephemeral redis, rate limits reset on pod restart
        container {
          name              = "redis"
          image             = "redis:7-alpine"
          image_pull_policy = "IfNotPresent"
          args              = ["--save", "", "--appendonly", "no", "--bind", "127.0.0.1"]
        }
      }
    }
  }

  depends_on = [kubernetes_namespace.gitlab_webhook_th]
}

resource "kubernetes_service_v1" "gitlab_webhook_th" {
  metadata {
    name      = "gitlab-webhook-th"
    namespace = var.gitlab_webhook_th_ns
  }

  spec {
    selector = {
      "app" = "gitlab-webhook-th"
    }

    port {
      port        = 3000
      target_port = 3000
    }
  }
}

resource "kubernetes_ingress_v1" "gitlab_webhook_th" {
  metadata {
    name      = "gitlab-webhook-th"
    namespace = var.gitlab_webhook_th_ns
    annotations = {
      "cert-manager.io/cluster-issuer"                           = var.cert_issuer_prod
      "external-dns.alpha.kubernetes.io/ingress-hostname-source" = "annotation-only"
      "external-dns.alpha.kubernetes.io/hostname"                = "gitlab-webhook-th.profidev.io"
      "external-dns.alpha.kubernetes.io/target"                  = "cluster.profidev.io"
    }
  }

  spec {
    ingress_class_name = var.ingress_class

    tls {
      hosts       = ["gitlab-webhook-th.profidev.io"]
      secret_name = "gitlab-webhook-th-tls"
    }

    rule {
      host = "gitlab-webhook-th.profidev.io"
      http {
        # /admin stays cluster-internal
        dynamic "path" {
          for_each = ["/webhook", "/health"]
          content {
            path      = path.value
            path_type = "Exact"
            backend {
              service {
                name = kubernetes_service_v1.gitlab_webhook_th.metadata[0].name
                port {
                  number = 3000
                }
              }
            }
          }
        }
      }
    }
  }
}

resource "kubectl_manifest" "gitlab_webhook_th_egress" {
  yaml_body = <<YAML
apiVersion: crd.projectcalico.org/v1
kind: GlobalNetworkPolicy
metadata:
  name: gitlab-webhook-th-egress
spec:
  order: 10
  namespaceSelector: kubernetes.io/metadata.name == '${var.gitlab_webhook_th_ns}'
  selector: app == 'gitlab-webhook-th'
  types:
    - Egress
  egress:
    - action: Allow
      protocol: TCP
      destination:
        ports:
          - 443
  YAML

  depends_on = [kubernetes_namespace.gitlab_webhook_th]
}

# Relay for api.anthropic.com, the TH runner network resets connections to it.
# Callers bring their own API key; the allowlist keeps it from being an open relay.
resource "kubectl_manifest" "anthropic_th_allowlist" {
  yaml_body = <<YAML
apiVersion: traefik.io/v1alpha1
kind: Middleware
metadata:
  name: anthropic-th-allowlist
  namespace: ${var.gitlab_webhook_th_ns}
spec:
  ipAllowList:
    sourceRange:
      - 141.60.0.0/16 # TH Rosenheim
  YAML

  depends_on = [kubernetes_namespace.gitlab_webhook_th]
}

resource "kubernetes_service_v1" "anthropic_th" {
  metadata {
    name      = "anthropic-th"
    namespace = var.gitlab_webhook_th_ns
    annotations = {
      "traefik.ingress.kubernetes.io/service.serversscheme"  = "https"
      "traefik.ingress.kubernetes.io/service.passhostheader" = "false"
    }
  }

  spec {
    type          = "ExternalName"
    external_name = "api.anthropic.com"

    port {
      port = 443
    }
  }
}

resource "kubernetes_ingress_v1" "anthropic_th" {
  metadata {
    name      = "anthropic-th"
    namespace = var.gitlab_webhook_th_ns
    annotations = {
      "cert-manager.io/cluster-issuer"                           = var.cert_issuer_prod
      "external-dns.alpha.kubernetes.io/ingress-hostname-source" = "annotation-only"
      "external-dns.alpha.kubernetes.io/hostname"                = "anthropic-th.profidev.io"
      "external-dns.alpha.kubernetes.io/target"                  = "cluster.profidev.io"
      "traefik.ingress.kubernetes.io/router.middlewares"         = "${var.gitlab_webhook_th_ns}-anthropic-th-allowlist@kubernetescrd"
    }
  }

  spec {
    ingress_class_name = var.ingress_class

    tls {
      hosts       = ["anthropic-th.profidev.io"]
      secret_name = "anthropic-th-tls"
    }

    rule {
      host = "anthropic-th.profidev.io"
      http {
        path {
          path      = "/"
          path_type = "Prefix"
          backend {
            service {
              name = kubernetes_service_v1.anthropic_th.metadata[0].name
              port {
                number = 443
              }
            }
          }
        }
      }
    }
  }

  depends_on = [kubectl_manifest.anthropic_th_allowlist]
}
