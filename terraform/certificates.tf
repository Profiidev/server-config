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
