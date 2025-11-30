variable "metrics_ns" {
  description = "Metrics namespace name"
  type        = string
}

variable "k8s_api" {
  description = "Kubernetes API server IP address"
  type        = string
  sensitive   = true
}
