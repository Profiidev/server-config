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

variable "hibernation_ns" {
  description = "The namespace where hibernation resources will be deployed"
  type        = string
  default     = "hibernation"
}

variable "ichwilldich_sep_ns" {
  description = "The namespace where ichwilldich sep resources will be deployed"
  type        = string
  default     = "ichwilldich-sep"
}

variable "ichtrackdich_ns" {
  description = "The namespace where ichtrackdich resources will be deployed"
  type        = string
  default     = "ichtrackdich"
}

variable "forgejo_ns" {
  description = "The namespace for Forgejo resources"
  type        = string
  default     = "forgejo"
}

variable "kubevirt_ns" {
  description = "The namespace where KubeVirt is deployed"
  type        = string
  default     = "kubevirt"
}

variable "sure_ns" {
  description = "The namespace where Sure is deployed"
  type        = string
  default     = "sure"
}

data "local_file" "ca_hash" {
  filename = "${path.module}/../storage/certs/ca.hash"
}

locals {
  ca_hash = data.local_file.ca_hash.content
}
