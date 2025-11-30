variable "lb_address_pool" {
  description = "Load Balancer Address Pool Name"
  type        = string
  default     = "lb-pool"
}

variable "lb_ns" {
  description = "Load Balancer Namespace"
  type        = string
  default     = "metallb"
}

variable "ingress_class" {
  description = "Ingress Class"
  type        = string
}

variable "cert_ns" {
  description = "Certificate Manager Namespace"
  type        = string
  default     = "cert-manager"
}

variable "cert_issuer_staging" {
  description = "Certificate Issuer for Staging"
  type        = string
}

variable "cert_issuer_prod" {
  description = "Certificate Issuer for Production"
  type        = string
}

variable "email" {
  description = "Email for Let's Encrypt"
  type        = string
}

variable "cluster_secret_store" {
  description = "Cluster Secret Store"
  type        = string
}

variable "crowdsec_ns" {
  description = "CrowdSec Namespace"
  type        = string
  default     = "crowdsec"
}

variable "k8s_api" {
  description = "The Kubernetes API server address"
  type        = string
  sensitive   = true
}

variable "storage_ns" {
  description = "The namespace for Storage resources"
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

