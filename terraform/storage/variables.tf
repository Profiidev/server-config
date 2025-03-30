variable "storage_class" {
  type    = string
  default = "longhorn"
}

variable "storage_ns" {
  description = "Storage Namespace"
  type        = string
  default     = "longhorn-system"
}
