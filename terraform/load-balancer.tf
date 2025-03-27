variable "lb_address_pool" {
  type    = string
  default = "lb_pool"
}

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

resource "helm_release" "metallb" {
  name       = "metallb"
  repository = "https://metallb.github.io/metallb"
  chart      = "metallb"
  version    = "0.14.9"
  namespace  = var.lb_ns

  depends_on = [kubernetes_namespace.lb_ns]
}

resource "kubernetes_manifest" "lb_ip_pool" {
  manifest = {
    apiVersion = "metallb.io/v1beta1"
    kind       = "IPAddressPool"
    metadata = {
      name      = var.lb_address_pool
      namespace = var.lb_ns
    }
    spec = {
      addresses = [
        "94.164.200.60/32"
      ]
    }
  }

  depends_on = [helm_release.metallb]
}

resource "kubernetes_manifest" "lb_l2_advertisement" {
  manifest = {
    apiVersion = "metallb.io/v1beta1"
    kind       = "L2Advertisement"
    metadata = {
      name      = var.lb_address_pool
      namespace = var.lb_ns
    }
    spec = {
      ipAddressPools = [
        var.lb_address_pool
      ]
    }
  }

  depends_on = [helm_release.metallb]
}
