variable "secrets_ns" {
  type = string
}

variable "vault_global_token" {
  type    = string
  default = "vault-global-token"
}

variable "vault_global_token_prop" {
  type    = string
  default = "token"
}

variable "storage_class" {
  type = string
}

variable "cluster_secret_store" {
  type = string
}

variable "secret_store_label" {
  type = object({
    key   = string
    value = string
  })
}

variable "vault_svc" {
  type    = string
  default = "vault"
}

variable "vault_cert_var" {
  type    = string
  default = "vault-server-tls"
}

variable "vault_cert_prop" {
  type    = string
  default = "vault"
}

variable "vault_csr" {
  type    = string
  default = "vault-csr"
}

variable "cluster_ca_cert_var" {
  type    = string
  default = "cluster-ca-cert"
}

variable "cluster_ca_cert_label" {
  type = object({
    key   = string
    value = string
  })
}

variable "oidc_access_label" {
  type = object({
    key   = string
    value = string
  })
}

variable "positron_ns" {
  type = string
}

variable "cloudflare_cert_label" {
  type = object({
    key   = string
    value = string
  })
}

variable "cloudflare_ca_cert_var" {
  type = string
}

variable "cloudflare_cert_var" {
  type = string
}

variable "ingress_class" {
  type = string
}

variable "ghcr_profidev" {
  type = string
}

variable "ghcr_profidev_label" {
  type = object({
    key   = string
    value = string
  })
}