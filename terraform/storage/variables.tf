variable "storage_class" {
  type = string
}

variable "minio_ns" {
  type = string
}

variable "everest_ns" {
  type = string
}

variable "everest_system_ns" {
  type    = string
  default = "everest-system"
}

variable "everest_olm_ns" {
  type    = string
  default = "everest-olm"
}

variable "everest_monitoring_ns" {
  type    = string
  default = "everest-monitoring"
}

variable "storage_ns" {
  description = "Storage Namespace"
  type        = string
  default     = "longhorn-system"
}

variable "ingress_class" {
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

variable "secret_store_label" {
  type = object({
    key   = string
    value = string
  })
}

variable "minio_config" {
  type    = string
  default = "minio-config"
}

variable "minio_config_label" {
  type = object({
    key   = string
    value = string
  })
  default = {
    key   = "minio-admin"
    value = "true"
  }
}

variable "cluster_secret_store" {
  type = string
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

variable "oidc_access_label" {
  type = object({
    key   = string
    value = string
  })
}

variable "positron_ns" {
  type = string
}

variable "cert_issuer_prod" {
  type = string
}
