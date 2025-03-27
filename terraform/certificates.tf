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

variable "cert-issuer-staging" {
  type    = string
  default = "letsencrypt-staging"
}

variable "cert-issuer-prod" {
  type    = string
  default = "letsencrypt-prod"
}

resource "kubernetes_manifest" "cert-issuer-staging" {
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

  depends_on = [ helm_release.cert-manager ]
}
