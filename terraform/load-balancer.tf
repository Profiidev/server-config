variable "lb_address_pool" {
  type    = string
  default = "lb_pool"
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
