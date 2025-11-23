variable "namespace" {
  type = string
}

variable "ingress_class" {
  type = string
}

variable "domain" {
  type = string
}

variable "name" {
  type = string
}

variable "cert_issuer" {
  type = string
}

variable "ip" {
  type = string
}

variable "port" {
  type = number
}

variable "cloudflare_ca_cert_var" {
  type = string
}

variable "cloudflare_cert_var" {
  type = string
}

variable "cloudflare" {
  type = bool
}

variable "https" {
  type = bool
}

variable "annotations" {
  type    = map(string)
  default = {}
}
