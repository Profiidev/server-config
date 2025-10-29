variable "couchdb_ns" {
  description = "The namespace where CouchDB will be deployed"
  type        = string
}

variable "cert_issuer_prod" {
  description = "The certificate issuer for production"
  type        = string
}

variable "cluster_secret_store" {
  description = "The name of the ClusterSecretStore to use for external secrets"
  type        = string
}

variable "minio_ns" {
  description = "The namespace where MinIO will be deployed"
  type        = string
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
}

variable "minio_config" {
  description = "The name of the MinIO configuration secret"
  type        = string
  default     = "minio-config"
}

variable "nats_ns" {
  description = "The namespace where NATS will be deployed"
  type        = string
}

variable "everest_system_ns" {
  description = "The namespace for Everest system components"
  type        = string
}

variable "everest_ns" {
  description = "The namespace for Everest components"
  type        = string
  default     = "everest"
}
