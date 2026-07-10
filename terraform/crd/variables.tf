variable "metrics_ns" {
  description = "Metrics namespace name"
  type        = string
}

variable "gateway_api_version" {
  description = "The API version for the Gateway API resources"
  type        = string
  default     = "v1.4.0"
}
