variable "lb_address_pool" {
  type    = string
  default = "lb-pool"
}

variable "lb_ns" {
  description = "Load Balancer Namespace"
  type        = string
  default     = "metallb-system"
}

variable "ingress_class" {
  type    = string
  default = "ingress-nginx"
}

variable "proxy_ns" {
  description = "Proxy Namespace"
  type        = string
  default     = "nginx-system"
}

variable "cert_ns" {
  description = "Certificate Manager Namespace"
  type        = string
  default     = "cert-system"
}

variable "cert_issuer_staging" {
  type    = string
  default = "letsencrypt-staging"
}

variable "cert_issuer_prod" {
  type    = string
  default = "letsencrypt-prod"
}

variable "email" {
  type    = string
  default = "mail@profidev.io"
}
