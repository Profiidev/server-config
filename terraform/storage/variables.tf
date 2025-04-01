variable "storage_class" {
  type    = string
  default = "longhorn"
}

variable "minio_ns" {
  type    = string
  default = "minio-system"
}

variable "everest_ns" {
  type    = string
  default = "everest"
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
  type    = string
  default = "ingress-nginx"
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
  type    = string
  default = "cluster-secret-store"
}
