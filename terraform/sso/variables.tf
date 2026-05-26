variable "positron_ns" {
  description = "The namespace where Positron is deployed"
  type        = string
  default     = "positron"
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
