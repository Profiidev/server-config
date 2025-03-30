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

variable "user_name" {
  type    = string
  default = "profidev"
}

variable "admin_group" {
  type    = string
  default = "admin"
}

variable "cluster_secret_store" {
  type    = string
  default = "cluster-secret-store"
}
