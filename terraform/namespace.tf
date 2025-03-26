// Storage
variable "storage-ns" {
  description = "Storage Namespace"
  type        = string
  default     = "longhorn-system"
}

resource "kubernetes_namespace" "storage-ns" {
  metadata {
    name = var.storage-ns
  }
}

// Load Balancer
variable "lb-ns" {
  description = "Load Balancer Namespace"
  type        = string
  default     = "metallb-system"
}

resource "kubernetes_namespace" "lb-ns" {
  metadata {
    name = var.lb-ns
  }
}

// Proxy
variable "proxy-ns" {
  description = "Proxy Namespace"
  type        = string
  default     = "nginx-system"
}

resource "kubernetes_namespace" "proxy-ns" {
  metadata {
    name = var.proxy-ns
  }
}

// Secrets
variable "secrets-ns" {
  description = "Secrets Namespace"
  type        = string
  default     = "secrets-system"
}

resource "kubernetes_namespace" "secrets-ns" {
  metadata {
    name = var.secrets-ns
  }
}

// Certificate Manager
variable "cert-ns" {
  description = "Certificate Manager Namespace"
  type        = string
  default     = "cert-system"
}

resource "kubernetes_namespace" "cert-ns" {
  metadata {
    name = var.cert-ns
  }
}

// Portainer
variable "portainer-ns" {
  description = "Portainer Namespace"
  type        = string
  default     = "portainer"
}

resource "kubernetes_namespace" "portainer-ns" {
  metadata {
    name = var.portainer-ns
    labels = {
      "${var.cloudflare-cert-label.key}" = var.cloudflare-cert-label.value
    }
  }
}
