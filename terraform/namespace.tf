// Storage
variable "storage_ns" {
  description = "Storage Namespace"
  type        = string
  default     = "longhorn-system"
}

resource "kubernetes_namespace" "storage_ns" {
  metadata {
    name = var.storage_ns
  }
}

// Load Balancer
variable "lb_ns" {
  description = "Load Balancer Namespace"
  type        = string
  default     = "metallb-system"
}

resource "kubernetes_namespace" "lb_ns" {
  metadata {
    name = var.lb_ns
  }
}

// Proxy
variable "proxy_ns" {
  description = "Proxy Namespace"
  type        = string
  default     = "nginx-system"
}

resource "kubernetes_namespace" "proxy_ns" {
  metadata {
    name = var.proxy_ns
  }
}

// Secrets
variable "secrets_ns" {
  description = "Secrets Namespace"
  type        = string
  default     = "secrets-system"
}

resource "kubernetes_namespace" "secrets_ns" {
  metadata {
    name = var.secrets_ns
    labels = {
      "${var.secret_store_label.key}" = var.secret_store_label.value
    }
  }
}

// Certificate Manager
variable "cert_ns" {
  description = "Certificate Manager Namespace"
  type        = string
  default     = "cert-system"
}

resource "kubernetes_namespace" "cert_ns" {
  metadata {
    name = var.cert_ns
  }
}

// Portainer
variable "portainer_ns" {
  description = "Portainer Namespace"
  type        = string
  default     = "portainer"
}

resource "kubernetes_namespace" "portainer_ns" {
  metadata {
    name = var.portainer_ns
    labels = {
      "${var.cloudflare_cert_label.key}" = var.cloudflare_cert_label.value
    }
  }
}
