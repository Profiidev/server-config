variable "ingress-class" {
  type    = string
  default = "ingress-nginx"
}

variable "storage-class" {
  type    = string
  default = "longhorn"
}

variable "email" {
  type = string
  default = "mail@profidev.io"
}
