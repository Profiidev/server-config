resource "kubernetes_namespace" "portainer_ns" {
  metadata {
    name = var.portainer_ns
    labels = {
      "${var.cloudflare_cert_label.key}" = var.cloudflare_cert_label.value
      "${var.secret_store_label.key}"    = var.secret_store_label.value
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
}
