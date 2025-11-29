variable "cluster_secret_store" {
  description = "The name of the ClusterSecretStore to use for external secrets"
  type        = string
}

variable "metrics_ns" {
  description = "The namespace where metrics components will be deployed"
  type        = string
}

variable "storage_class" {
  description = "The storage class to use for persistent volumes"
  type        = string
}

variable "ingress_class" {
  description = "The ingress class to use for ingress resources"
  type        = string
}

variable "cloudflare_cert_var" {
  description = "The name of the secret variable containing the Cloudflare certificate"
  type        = string
}

variable "cloudflare_ca_cert_var" {
  description = "The name of the secret variable containing the Cloudflare CA certificate"
  type        = string
}

variable "argo_ns" {
  description = "The namespace where ArgoCD is deployed"
  type        = string
}

variable "k8s_api" {
  description = "The Kubernetes API endpoint"
  type        = string
}

data "local_file" "ca_hash" {
  filename = "${path.module}/../storage/certs/ca.hash"
}

locals {
  ca_hash = data.local_file.ca_hash.content
}
