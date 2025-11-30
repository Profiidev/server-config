variable "couchdb_ns" {
  description = "The namespace where CouchDB will be deployed"
  type        = string
  default     = "couchdb"
}

variable "cert_issuer_prod" {
  description = "The certificate issuer for production"
  type        = string
}

variable "cluster_secret_store" {
  description = "The name of the ClusterSecretStore to use for external secrets"
  type        = string
}

variable "rustfs_ns" {
  description = "The namespace where MinIO will be deployed"
  type        = string
  default     = "rustfs"
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

variable "k8s_api" {
  description = "The Kubernetes API server address"
  type        = string
  sensitive   = true
}

variable "minio_config" {
  description = "The name of the MinIO configuration secret"
  type        = string
  default     = "minio-config"
}

variable "nats_ns" {
  description = "The namespace where NATS will be deployed"
  type        = string
  default     = "nats"
}

variable "pg_ns" {
  description = "The namespace where PostgreSQL will be deployed"
  type        = string
  default     = "postgres"
}

variable "rustfs_password" {
  description = "Rustfs password"
  type        = string
}
