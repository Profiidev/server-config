variable "ingress_class" {
  type    = string
  default = "ingress-nginx"
}

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

resource "helm_release" "ingress_nginx" {
  name       = "ingress-nginx"
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  version    = "4.12.1"
  namespace  = var.proxy_ns

  values = [templatefile("${path.module}/../helm/ingress-nginx.values.tftpl", {
    ingress_class = var.ingress_class
  })]

  depends_on = [kubernetes_namespace.proxy_ns]
}
