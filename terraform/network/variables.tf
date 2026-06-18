variable "ingress_class" {
  description = "Ingress Class"
  type        = string
}

variable "cert_ns" {
  description = "Certificate Manager Namespace"
  type        = string
  default     = "cert-manager"
}

variable "tailscale_ns" {
  description = "The namespace for Tailscale resources"
  type        = string
  default     = "tailscale"
}

variable "cert_issuer_staging" {
  description = "Certificate Issuer for Staging"
  type        = string
}

variable "cert_issuer_prod" {
  description = "Certificate Issuer for Production"
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

variable "external_dns_ns" {
  description = "External DNS Namespace"
  type        = string
  default     = "external-dns"
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

variable "node1" {
  type = string
}

variable "node2" {
  type = string
}

variable "node3" {
  type = string
}
