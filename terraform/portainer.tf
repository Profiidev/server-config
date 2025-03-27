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

resource "helm_release" "portainer" {
  name       = "portainer"
  repository = "https://portainer.github.io/k8s"
  chart      = "portainer"
  version    = "1.0.63"
  namespace  = var.portainer_ns

  values = [templatefile("${path.module}/../helm/portainer.values.tftpl", {
    namespace              = var.portainer_ns
    cloudflare_ca_cert_var = var.cloudflare_ca_cert_var
    cloudflare_cert_var    = var.cloudflare_cert_var
    ingress_class          = var.ingress_class
  })]

  depends_on = [kubernetes_namespace.portainer_ns]
}
