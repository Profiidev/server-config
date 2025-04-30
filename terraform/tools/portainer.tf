resource "kubernetes_namespace" "portainer_ns" {
  metadata {
    name = var.portainer_ns
    labels = {
      "${var.cloudflare_cert_label.key}" = var.cloudflare_cert_label.value
      "${var.secret_store_label.key}"    = var.secret_store_label.value
      "${var.oidc_access_label.key}"     = var.oidc_access_label.value
    }
  }
}

resource "helm_release" "portainer" {
  name       = "portainer"
  repository = "https://portainer.github.io/k8s"
  chart      = "portainer"
  version    = "1.0.63"
  namespace  = var.portainer_ns

  values = [templatefile("${path.module}/templates/portainer.values.tftpl", {
    namespace              = var.portainer_ns
    cloudflare_ca_cert_var = var.cloudflare_ca_cert_var
    cloudflare_cert_var    = var.cloudflare_cert_var
    ingress_class          = var.ingress_class
  })]

  depends_on = [kubernetes_namespace.portainer_ns]
}

resource "kubectl_manifest" "portainer_ingress" {
  yaml_body = <<YAML
apiVersion: crd.projectcalico.org/v1
kind: NetworkPolicy
metadata:
  name: portainer-ingress
  namespace: ${var.portainer_ns}
spec:
  order: 10
  selector: app.kubernetes.io/instance == 'portainer'
  types:
    - Ingress
  ingress:
    - action: Allow
      protocol: TCP
      source:
        namespaceSelector: kubernetes.io/metadata.name == 'kube-system'
        selector: app.kubernetes.io/name == 'rke2-ingress-nginx'
      destination:
        ports:
          - 9000
  YAML

  depends_on = [kubernetes_namespace.portainer_ns]
}

resource "kubectl_manifest" "portainer_k8s_api_egress" {
  yaml_body = <<YAML
apiVersion: crd.projectcalico.org/v1
kind: NetworkPolicy
metadata:
  name: k8s-api-egress
  namespace: ${var.portainer_ns}
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

  depends_on = [kubernetes_namespace.portainer_ns]
}
