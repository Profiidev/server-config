variable "email" {
  type    = string
  default = "mail@profidev.io"
}

variable "ingress_class" {
  type    = string
  default = "ingress-nginx"
}

variable "storage_class" {
  type    = string
  default = "longhorn"
}

variable "cloudflare_ca_cert_var" {
  type    = string
  default = "cloudflare-ca-cert"
}

variable "cloudflare_cert_var" {
  type    = string
  default = "cloudflare-cert"
}

variable "cloudflare_cert_label" {
  type = object({
    key   = string
    value = string
  })
  default = {
    key   = "cloudflare-cert-secret"
    value = "true"
  }
}

variable "cluster_secret_store" {
  type    = string
  default = "cluster-secret-store"
}

variable "secret_store_label" {
  type = object({
    key   = string
    value = string
  })
  default = {
    key   = "secret-store"
    value = "true"
  }
}
