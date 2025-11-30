variable "proton_ns" {
  description = "The namespace where Proton is deployed"
  type        = string
  default     = "proton"
}

variable "positron_ns" {
  description = "The namespace where Positron is deployed"
  type        = string
  default     = "positron"
}

variable "nextcloud_ns" {
  description = "The namespace where Nextcloud is deployed"
  type        = string
  default     = "nextcloud"
}

variable "argo_ns" {
  description = "The namespace where ArgoCD is deployed"
  type        = string
}

variable "cluster_secret_store" {
  description = "The name of the ClusterSecretStore to use for external secrets"
  type        = string
}

variable "cloudflare_cert_var" {
  description = "The Vault variable name for the Cloudflare certificate"
  type        = string
}

variable "cloudflare_ca_cert_var" {
  description = "The Vault variable name for the Cloudflare CA certificate"
  type        = string
}

variable "ingress_class" {
  description = "The ingress class to be used"
  type        = string
}

variable "ghcr_profidev" {
  description = "The GitHub Container Registry for ProfiDev images"
  type        = string
}

variable "cert_issuer_prod" {
  description = "The cert-manager issuer to use for production certificates"
  type        = string
}

variable "storage_class" {
  description = "The storage class to use for persistent volumes"
  type        = string
}

variable "k8s_api" {
  description = "The Kubernetes API server URL"
  type        = string
}

data "local_file" "ca_hash" {
  filename = "${path.module}/../storage/certs/ca.hash"
}

locals {
  ca_hash = data.local_file.ca_hash.content
}
