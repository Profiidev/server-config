variable "lb-address-pool" {
  type    = string
  default = "lb_pool"
}

resource "kubernetes_manifest" "lb_ip_pool" {
  manifest = {
    apiVersion = "metallb.io/v1beta1"
    kind       = "IPAddressPool"
    metadata = {
      name      = var.lb-address-pool
      namespace = var.lb-ns
    }
    spec = {
      addresses = [
        "94.164.200.60/32"
      ]
    }
  }

  depends_on = [ helm_release.metallb ]
}

resource "kubernetes_manifest" "lb_l2_advertisement" {
  manifest = {
    apiVersion = "metallb.io/v1beta1"
    kind       = "L2Advertisement"
    metadata = {
      name      = var.lb-address-pool
      namespace = var.lb-ns
    }
    spec = {
      ipAddressPools = [
        var.lb-address-pool
      ]
    }
  }

  depends_on = [ helm_release.metallb ]
}
