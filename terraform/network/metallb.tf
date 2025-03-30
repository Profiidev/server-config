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

resource "kubectl_manifest" "lb_ip_pool" {
  yaml_body = <<YAML
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: ${var.lb_address_pool}
  namespace: ${var.lb_ns}
spec:
  addresses:
    - "94.164.200.60/32"
  YAML

  depends_on = [helm_release.metallb]
}

resource "kubectl_manifest" "lb_l2_advertisement" {
  yaml_body = <<YAML
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: ${var.lb_address_pool}
  namespace: ${var.lb_ns}
spec:
  ipAddressPools:
    - ${var.lb_address_pool}
  YAML

  depends_on = [helm_release.metallb]
}
