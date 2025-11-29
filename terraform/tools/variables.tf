variable "argo_ns" {
  description = "The namespace where ArgoCD is deployed"
  type        = string
}

variable "ingress_class" {
  description = "The ingress class to be used"
  type        = string
}

variable "cert_issuer_prod" {
  description = "The certificate issuer for production"
  type        = string
}

variable "cluster_secret_store" {
  description = "The name of the cluster secret store"
  type        = string
}

variable "k8s_api" {
  description = "The Kubernetes API server address"
  type        = string
  sensitive   = true
}

variable "coder_ns" {
  description = "The namespace for Coder resources"
  type        = string
  default     = "coder"
}

variable "tailscale_ns" {
  description = "The namespace for Tailscale resources"
  type        = string
  default     = "tailscale"
}


variable "cloudflare_cert_var" {
  description = "The Vault variable name for the Cloudflare certificate"
  type        = string
}

variable "cloudflare_ca_cert_var" {
  description = "The Vault variable name for the Cloudflare CA certificate"
  type        = string
}
