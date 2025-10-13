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
  type = string
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

variable "cluster_secret_store" {
  type = string
}

variable "secret_store_label" {
  type = object({
    key   = string
    value = string
  })
}

variable "crowdsec_ns" {
  type    = string
  default = "crowdsec"
}
