variable "namespace" {
  description = "The namespace that wants to talk to the k8s api"
  type        = string
}

variable "selector" {
  description = "The label selector to use for the ingress network policy"
  type        = string
}
