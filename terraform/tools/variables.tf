variable "portainer_ns" {
  description = "Portainer Namespace"
  type        = string
  default     = "portainer"
}

variable "cloudflare_cert_label" {
  type = object({
    key   = string
    value = string
  })
}

variable "cloudflare_ca_cert_var" {
  type    = string
}

variable "cloudflare_cert_var" {
  type    = string
}

variable "secret_store_label" {
  type = object({
    key   = string
    value = string
  })
}

variable "ingress_class" {
  type    = string
}

variable "cluster_secret_store" {
  type    = string
  default = "cluster-secret-store"
}

variable "positron_ns" {
  type    = string
  default = "positron"
}

variable "minio_access_label" {
  type = object({
    key   = string
    value = string
  })
}

variable "postgres_access_label" {
  type = object({
    key   = string
    value = string
  })
}

variable "everest_ns" {
  type    = string
}

variable "minio_ns" {
  type    = string
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
  default = {
    key   = "oidc-access"
    value = "true"
  }
}
