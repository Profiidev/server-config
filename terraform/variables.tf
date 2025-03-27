variable "ingress_class" {
  type    = string
  default = "ingress-nginx"
}

variable "storage_class" {
  type    = string
  default = "longhorn"
}

variable "email" {
  type    = string
  default = "mail@profidev.io"
}
