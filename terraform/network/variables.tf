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
  type = string
}

variable "cert_ns" {
  description = "Certificate Manager Namespace"
  type        = string
  default     = "cert-system"
}

variable "cert_issuer_staging" {
  type = string
}

variable "cert_issuer_prod" {
  type = string
}

variable "email" {
  type = string
}
