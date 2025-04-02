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
  default = {
    key   = "cloudflare-cert-secret"
    value = "true"
  }
}

variable "cloudflare_ca_cert_var" {
  type    = string
  default = "cloudflare-ca-cert"
}

variable "cloudflare_cert_var" {
  type    = string
  default = "cloudflare-cert"
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

variable "ingress_class" {
  type    = string
  default = "ingress-nginx"
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
  default = {
    key   = "minio-access"
    value = "true"
  }
}

variable "postgres_access_label" {
  type = object({
    key   = string
    value = string
  })
  default = {
    key   = "postgres-access"
    value = "true"
  }
}

variable "everest_ns" {
  type    = string
  default = "everest"
}

variable "minio_ns" {
  type    = string
  default = "minio-system"
}

variable "cluster_ca_cert_label" {
  type = object({
    key   = string
    value = string
  })
  default = {
    key   = "cluster-ca-cert"
    value = "true"
  }
}
