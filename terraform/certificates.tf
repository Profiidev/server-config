variable "cluster-ca-cert-var" {
  type    = string
  default = "cluster-ca-cert"
}

variable "cloudflare-ca-cert-var" {
  type    = string
  default = "cloudflare_ca_cert"
}

variable "cloudflare-cert-var" {
  type    = string
  default = "cloudflare_cert"
}

variable "vault-cert-var" {
  type    = string
  default = "vault-server-tls"
}

variable "vault-cert-prop" {
  type    = string
  default = "vault"
}

variable "cloudflare-cert-label" {
  type = object({
    key   = string
    value = string
  })
  default = {
    key   = "cloudflare_cert_secret"
    value = "true"
  }
}

variable "cluster-ca-cert-label" {
  type = object({
    key   = string
    value = string
  })
  default = {
    key   = "cluster_ca_cert"
    value = "true"
  }
}

variable "cert-issuer-staging" {
  type    = string
  default = "letsencrypt-staging"
}

variable "cert-issuer-prod" {
  type    = string
  default = "letsencrypt-prod"
}

resource "kubernetes_manifest" "cert-issuer" {
  for_each = tomap({
    staging = "https://acme-staging-v02.api.letsencrypt.org/directory"
    prod    = "https://acme-v02.api.letsencrypt.org/directory"
  })

  manifest = {
    apiVersion = "cert-manager.io/v1"
    kind       = "ClusterIssuer"
    metadata = {
      name = each.key == "prod" ? var.cert-issuer-prod : var.cert-issuer-staging
    }
    spec = {
      acme = {
        email  = var.email
        server = each.value
        privateKeySecretRef = {
          name = "letsencrypt-${each.key}-issuer-account-key"
        }
        solvers = [
          {
            http01 = {
              ingress = {
                ingressClassName = var.ingress-class
              }
            }
          }
        ]
      }
    }
  }

  depends_on = [helm_release.cert-manager]
}

resource "kubernetes_manifest" "cloudflare-cert" {
  for_each = tomap({
    "${var.cloudflare-cert-var}"    = ["tls.crt", "tls.key"]
    "${var.cloudflare-ca-cert-var}" = ["ca.crt"]
  })

  manifest = {
    apiVersion = "external-secrets.io/v1beta1"
    kind       = "ClusterExternalSecret"
    metadata = {
      name = each.key
    }
    spec = {
      externalSecretName = each.key
      namespaceSelectors = [
        {
          matchLabels = {
            "${var.cloudflare-cert-label.key}" = var.cloudflare-cert-label.value
          }
        }
      ]
      refreshTime = "15s"

      externalSecretSpec = {
        target = {
          name = each.key
        }
        refreshInterval = "15s"
        secretStoreRef = {
          name = var.cluster-secret-store
          kind = "ClusterSecretStore"
        }
        data = [
          for value in each.value : {
            secretKey = value
            remoteRef = {
              key      = "certs/cloudflare"
              property = value
            }
          }
        ]
      }
    }
  }

  depends_on = [helm_release.external-secrets]
}

resource "kubernetes_manifest" "cluster-ca-cert" {
  manifest = {
    apiVersion = "external-secrets.io/v1beta1"
    kind       = "ClusterExternalSecret"
    metadata = {
      name = var.cluster-ca-cert-var
    }
    spec = {
      externalSecretName = var.cluster-ca-cert-var
      namespaceSelectors = [
        {
          matchLabels = {
            "${var.cluster-ca-cert-label.key}" = var.cluster-ca-cert-label.value
          }
        }
      ]
      refreshTime = "15s"

      externalSecretSpec = {
        target = {
          name = var.cluster-ca-cert-var
        }
        refreshInterval = "15s"
        secretStoreRef = {
          name = var.cluster-secret-store
          kind = "ClusterSecretStore"
        }
        data = [
          {
            secretKey = "ca.crt"
            remoteRef = {
              key      = "certs/cluster"
              property = "ca.crt"
            }
          }
        ]
      }
    }
  }

  depends_on = [helm_release.external-secrets]
}
