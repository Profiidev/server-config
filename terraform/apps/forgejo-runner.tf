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
        "runner-config.yaml": |
          server:
            connections:
              forgejo:
                url: https://git.profidev.io/
                token: {{ index . "${each.key}-token" }}
                uuid: {{ index . "${each.key}-uuid" }}
          runner:
            name: ${each.key}
            capacity: 10
            labels:
              - nixos-latest:docker://nixos/nix
              - ubuntu-latest:docker://catthehacker/ubuntu:act-latest
              - rust-latest:docker://catthehacker/ubuntu:rust-latest
              - node-latest:docker://catthehacker/ubuntu:js-latest
              - gh-latest:docker://catthehacker/ubuntu:gh-latest
          cache:
            enabled: true
            secret: {{ index . "CACHE_SECRET" }}
            external_server: "http://forgejo-runner-cache.forgejo.svc.cluster.local:8000"
  dataFrom:
  - extract:
      key: tools/forgejo-runner
  YAML

  depends_on = [kubernetes_namespace.forgejo]
}

resource "kubernetes_persistent_volume_claim" "forgejo_runner_storage" {
  for_each = { for vm in ["node1", "node2", "node3"] : vm => vm }

  metadata {
    name      = "forgejo-runner-storage-${each.key}"
    namespace = var.forgejo_ns
  }
  spec {
    access_modes = ["ReadWriteOnce"]
    resources {
      requests = {
        storage = "30Gi"
      }
    }
  }

  depends_on = [kubernetes_namespace.forgejo]
}
