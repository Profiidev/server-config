variable "metrics_ns" {
  type = string
}

variable "namespace" {
  type = string
}

variable "name" {
  type = string
}

variable "port" {
  type = number
}

variable "selector" {
  type     = string
  nullable = true
  default  = null
}
