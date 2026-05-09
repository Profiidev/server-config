variable "metrics_ns" {
  description = "Metrics namespace name"
  type        = string
}

variable "k8s_api" {
  description = "Kubernetes API server IP address"
  type        = string
  sensitive   = true
}

variable "gateway_api_version" {
  description = "The API version for the Gateway API resources"
  type        = string
  default = "v1.4.0"
}
