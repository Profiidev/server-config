variable "namespace" {
  description = "The namespace that wants to talk to the k8s api"
  type        = string
}

variable "k8s_api" {
  description = "The effective Kubernetes API server address"
  type        = string
  sensitive   = true
}
