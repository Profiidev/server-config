variable "k8s_api" {
  description = "Kubernetes API server address"
  type        = string
  sensitive   = true
}

variable "smtp_password" {
  description = "SMTP password for sending emails"
  type        = string
  sensitive   = true
}

variable "email" {
  description = "Administrator email address"
  type        = string
  sensitive   = true
}

variable "cert_issuer_prod" {
  description = "Certificate issuer for production environment"
  type        = string
}

variable "cloudflare_cert_var" {
  description = "Cloudflare certificate variable"
  type        = string
}

variable "cloudflare_ca_cert_var" {
  description = "Cloudflare CA certificate variable"
  type        = string
}

variable "ingress_class" {
  description = "Ingress class for Kubernetes"
  type        = string
}

variable "docker_ns" {
  description = "Docker namespace in Kubernetes"
  type        = string
  default     = "docker"
}
