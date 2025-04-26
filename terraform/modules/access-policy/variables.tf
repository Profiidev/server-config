variable "namespace_label" {
  type = object({
    key   = string
    value = string
  })
}

variable "namespace" {
  type = string
}

variable "selector" {
  type = string
}

variable "port" {
  type = number
}
