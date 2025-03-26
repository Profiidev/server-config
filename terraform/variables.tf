variable "ingress-class" {
  type    = string
  default = "ingress-nginx"
}

variable "storage-class" {
  type    = string
  default = "longhorn"
}
