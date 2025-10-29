variable "lb_address_pool" {
  description = "Load Balancer Address Pool Name"
  type        = string
  default     = "lb-pool"
}

variable "lb_ns" {
  description = "Load Balancer Namespace"
  type        = string
}

variable "ingress_class" {
  description = "Ingress Class"
  type        = string
}

variable "cert_ns" {
  description = "Certificate Manager Namespace"
  type        = string
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
}

variable "k8s_api" {
  description = "The Kubernetes API server address"
  type        = string
}
