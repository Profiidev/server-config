variable "ingress-class" {
  type    = string
  default = "ingress-nginx"
}

variable "storage-class" {
  type    = string
  default = "longhorn"
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
