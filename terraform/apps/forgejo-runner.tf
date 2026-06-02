resource "kubectl_manifest" "forgejo_runner_secret" {
  for_each = { for vm in ["node1", "node2", "node3"] : vm => vm }

  yaml_body = <<YAML
apiVersion: external-secrets.io/v1
kind: ExternalSecret
metadata:
  name: forgejo-runner-secret-${each.key}
  namespace: ${var.forgejo_ns}
spec:
  refreshInterval: 5m
  secretStoreRef:
    name: ${var.cluster_secret_store}
    kind: ClusterSecretStore
  target:
    name: forgejo-runner-secret-${each.key}
    template:
      engineVersion: v2
      data:
        "config.yaml": |
          server:
            connections:
              forgejo:
                url: https://git.profidev.io/
                token: {{ index . "${each.key}-token" }}
                uuid: {{ index . "${each.key}-uuid" }}
          runner:
            name: ${each.key}
            capacity: 2
            labels:
              - nixos-latest:docker://nixos/nix
              - ubuntu-latest:docker://catthehacker/ubuntu:act-latest
              - rust-latest:docker://catthehacker/ubuntu:rust-latest
              - node-latest:docker://catthehacker/ubuntu:js-latest
              - gh-latest:docker://catthehacker/ubuntu:gh-latest
          cache:
            enabled: true
            secret: {{ index . "CACHE_SECRET" }}
            external_server: "http://forgejo-runner-s3-cache.forgejo.svc.cluster.local:8000"
          container:
            docker_host: 'automount'
  dataFrom:
  - extract:
      key: tools/forgejo-runner
  YAML

  depends_on = [kubernetes_namespace.forgejo]
}

resource "kubernetes_stateful_set_v1" "forgejo_runner" {
  metadata {
    name      = "forgejo-runner"
    namespace = var.forgejo_ns
  }

  spec {
    service_name = "forgejo-runner"
    replicas = 3

    selector {
      match_labels = {
        "app" = "forgejo-runner"
      }
    }

    template {
      metadata {
        labels = {
          "app" = "forgejo-runner"
        }
      }

      spec {
        affinity {
          pod_anti_affinity {
            required_during_scheduling_ignored_during_execution {
              topology_key = "kubernetes.io/hostname"

              label_selector {
                match_expressions {
                  key = "app"
                  operator = "In"
                  values = ["forgejo-runner"]
                }
              }
            }
          }
        }

        # Init Container matches the local node name to the specific generated secret
        init_container {
          name              = "config-setup"
          image             = "busybox:latest"
          image_pull_policy = "IfNotPresent"

          command = [
            "sh", "-c", <<EOF
            cp /secrets/$NODE_NAME/config.yaml /forgejo/config/config.yaml
            chown 1000:1000 /forgejo/config/config.yaml
            chown 1000:1000 /data
            mkdir -p /data/.cache
            chown 1000:1000 /data/.cache
            EOF
          ]

          # Inject the Host's node name into an environment variable
          env {
            name = "NODE_NAME"
            value_from {
              field_ref {
                field_path = "spec.nodeName"
              }
            }
          }

          volume_mount {
            name       = "storage"
            mount_path = "/data"
            sub_path   = "cache"
          }

          volume_mount {
            name       = "config"
            mount_path = "/forgejo/config"
          }

          # Mount all discrete node secret volumes to pick at runtime
          dynamic "volume_mount" {
            for_each = ["node1", "node2", "node3"]
            content {
              name       = "secret-${volume_mount.value}"
              mount_path = "/secrets/${volume_mount.value}"
              read_only  = true
            }
          }
        }

        container {
          name              = "runner"
          image             = "data.forgejo.org/forgejo/runner:12.10.2"
          image_pull_policy = "IfNotPresent"

          env {
            name  = "DOCKER_HOST"
            value = "unix:///forgejo/run/docker.sock"
          }

          command = ["/bin/sh", "-c"]
          args    = ["sleep 2; forgejo-runner daemon --config /forgejo/config/config.yaml"]

          security_context {
            run_as_user = 1000
            run_as_group = 1000
          }

          volume_mount {
            name       = "config"
            mount_path = "/forgejo/config"
          }

          volume_mount {
            name       = "storage"
            mount_path = "/data"
            sub_path   = "cache"
          }

          volume_mount {
            name       = "socket"
            mount_path = "/forgejo/run"
          }
        }

        container {
          name              = "dind"
          image             = "docker:dind"
          image_pull_policy = "IfNotPresent"

          security_context {
            privileged = true
          }

          command = [
            "dockerd",
            "-H",
            "unix:///forgejo/run/docker.sock",
            "-G",
            "1000"
          ]

          volume_mount {
            name       = "storage"
            mount_path = "/var/lib/docker"
            sub_path   = "dind"
          }

          volume_mount {
            name       = "socket"
            mount_path = "/forgejo/run"
          }
        }

        volume {
          name = "config"
          empty_dir {}
        }

        volume {
          name = "socket"
          empty_dir {}
        }

        dynamic "volume" {
          for_each = ["node1", "node2", "node3"]
          content {
            name = "secret-${volume.value}"
            secret {
              secret_name = "forgejo-runner-secret-${volume.value}"
            }
          }
        }
      }
    }

    volume_claim_template {
      metadata {
        name = "storage"
      }

      spec {
        access_modes = ["ReadWriteOnce"]
        resources {
          requests = {
            storage = "30Gi"
          }
        }
      }
    }
  }

  depends_on = [kubernetes_namespace.forgejo]
}
