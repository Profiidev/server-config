variable "cert_issuer_prod" {
  description = "The certificate issuer for production"
  type        = string
}

variable "cluster_secret_store" {
  description = "The name of the ClusterSecretStore to use for external secrets"
  type        = string
}

variable "garage_ns" {
  description = "The namespace where MinIO will be deployed"
  type        = string
  default     = "garage"
}

variable "storage_class" {
  description = "The storage class to use for persistent volumes"
  type        = string
}

variable "cloudflare_ca_cert_var" {
  description = "The variable name for the Cloudflare CA certificate"
  type        = string
}

variable "cloudflare_cert_var" {
  description = "The variable name for the Cloudflare certificate"
  type        = string
}

variable "ingress_class" {
  description = "The ingress class to use for ingress resources"
  type        = string
}

variable "pg_ns" {
  description = "The namespace where PostgreSQL will be deployed"
  type        = string
  default     = "postgres"
}

variable "secrets_ns" {
  description = "The namespace where secrets will be stored"
  type        = string
}
