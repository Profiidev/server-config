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

variable "nats_access_label" {
  type = object({
    key   = string
    value = string
  })
  default = {
    key   = "nats-access"
    value = "true"
  }
}

variable "positron_ns" {
  type    = string
  default = "positron"
}

variable "cert_issuer_staging" {
  type    = string
  default = "letsencrypt-staging"
}

variable "cert_issuer_prod" {
  type    = string
  default = "letsencrypt-prod"
}

variable "cert_ns" {
  type    = string
  default = "cert-system"
}

variable "secrets_ns" {
  type    = string
  default = "secrets-system"
}

variable "storage_ns" {
  type    = string
  default = "longhorn-system"
}

variable "metrics_ns" {
  type    = string
  default = "metrics-system"
}

variable "everest_system_ns" {
  type    = string
  default = "everest-system"
}

variable "nats_ns" {
  type    = string
  default = "nats-system"
}

variable "ghcr_profidev" {
  type    = string
  default = "ghcr-profidev"
}

variable "ghcr_profidev_label" {
  type = object({
    key   = string
    value = string
  })
  default = {
    key   = "ghcr-profidev-secret"
    value = "true"
  }
}
