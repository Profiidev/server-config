variable "cluster-secret-store" {
  type    = string
  default = "cluster-secret-store"
}

variable "vault-global-token" {
  type    = string
  default = "vault-global-token"
}

variable "vault-global-token-prop" {
  type    = string
  default = "token"
}

variable "secret-store-label" {
  type = object({
    key   = string
    value = string
  })
  default = {
    key   = "secret_store"
    value = "true"
  }
}

resource "kubernetes_manifest" "cluster-secret-store" {
  manifest = {
    apiVersion = "external-secrets.io/v1beta1"
    kind       = "ClusterSecretStore"
    metadata = {
      name = var.cluster-secret-store
    }
    spec = {
      provider = {
        vault = {
          server  = "https://vault.vault.svc:8200"
          path    = "kv"
          version = "v2"
          auth = {
            tokenSecretRef = {
              namespace = var.secrets-ns
              name      = var.vault-global-token
              key       = var.vault-global-token-prop
            }
          }
        }
      }

      conditions = [
        {
          namespaceSelector = {
            matchLabels = {
              "${var.secret-store-label.key}" = var.secret-store-label.value
            }
          }
        }
      ]
    }
  }

  depends_on = [helm_release.external-secrets]
}
