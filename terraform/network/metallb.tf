resource "kubernetes_namespace" "lb" {
  metadata {
    name = var.lb_ns
  }
}

resource "helm_release" "metallb" {
  name       = "metallb"
  repository = "https://metallb.github.io/metallb"
  chart      = "metallb"
  version    = "0.15.2"
  namespace  = var.lb_ns

  depends_on = [kubernetes_namespace.lb]
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
    - "${var.k8s_api}/32"
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

module "k8s_api_np_metallb" {
  source = "../modules/k8s-api-np"

  namespace = var.lb_ns
  k8s_api   = var.k8s_api

  depends_on = [kubernetes_namespace.lb]
}

module "egress_np_metallb" {
  source = "../modules/external-np"

  namespace = var.lb_ns

  depends_on = [kubernetes_namespace.lb]
}
