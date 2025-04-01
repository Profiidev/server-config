variable "storage_class" {
  type    = string
  default = "longhorn"
}

variable "everest_ns" {
  type    = string
  default = "everest"
}

variable "everest_system_ns" {
  type    = string
  default = "everest-system"
}

variable "everest_olm_ns" {
  type    = string
  default = "everest-olm"
}

variable "everest_monitoring_ns" {
  type    = string
  default = "everest-monitoring"
}

variable "storage_ns" {
  description = "Storage Namespace"
  type        = string
  default     = "longhorn-system"
}

variable "ingress_class" {
  type    = string
  default = "ingress-nginx"
}
