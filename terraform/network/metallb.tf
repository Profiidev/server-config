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
    - "194.164.200.60/32"
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

resource "kubectl_manifest" "metallb_k8s_api_egress" {
  yaml_body = <<YAML
apiVersion: crd.projectcalico.org/v1
kind: NetworkPolicy
metadata:
  name: k8s-api-egress
  namespace: ${var.lb_ns}
spec:
  order: 10
  types:
    - Egress
  egress:
    - action: Allow
      protocol: TCP
      destination:
        nets:
          - 194.164.200.60/32
          - 172.17.0.0/16
        ports:
          - 6443
          - 9001
    - action: Allow
      protocol: TCP
      destination:
        notNets:
          - 10.0.0.0/8
          - 172.16.0.0/12
          - 192.168.0.0/16
        ports:
          - 443
  YAML

  depends_on = [kubernetes_namespace.lb_ns]
}
