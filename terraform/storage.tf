variable "storage_class" {
  type    = string
  default = "longhorn"
}

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

resource "helm_release" "longhorn" {
  name       = "longhorn"
  repository = "https://charts.longhorn.io"
  chart      = "longhorn"
  version    = "1.8.1"
  namespace  = var.storage_ns

  depends_on = [kubernetes_namespace.storage_ns]
}
