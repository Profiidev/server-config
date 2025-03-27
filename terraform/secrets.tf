variable "cluster_secret_store" {
  type    = string
  default = "cluster-secret-store"
}

variable "vault_global_token" {
  type    = string
  default = "vault-global-token"
}

variable "vault_global_token_prop" {
  type    = string
  default = "token"
}

variable "secret_store_label" {
  type = object({
    key   = string
    value = string
  })
  default = {
    key   = "secret_store"
    value = "true"
  }
}

resource "kubernetes_manifest" "cluster_secret_store" {
  manifest = {
    apiVersion = "external-secrets.io/v1beta1"
    kind       = "ClusterSecretStore"
    metadata = {
      name = var.cluster_secret_store
    }
    spec = {
      provider = {
        vault = {
          server  = "https://vault.vault.svc:8200"
          path    = "kv"
          version = "v2"
          auth = {
            tokenSecretRef = {
              namespace = var.secrets_ns
              name      = var.vault_global_token
              key       = var.vault_global_token_prop
            }
          }
        }
      }

      conditions = [
        {
          namespaceSelector = {
            matchLabels = {
              "${var.secret_store_label.key}" = var.secret_store_label.value
            }
          }
        }
      ]
    }
  }

  depends_on = [helm_release.external_secrets]
}
