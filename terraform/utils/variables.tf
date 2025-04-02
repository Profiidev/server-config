variable "cloudflare_ca_cert_var" {
  type    = string
}

variable "cloudflare_cert_var" {
  type    = string
}

variable "cloudflare_cert_label" {
  type = object({
    key   = string
    value = string
  })
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
}
