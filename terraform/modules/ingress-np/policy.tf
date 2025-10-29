resource "kubectl_manifest" "ingress_np" {
  yaml_body = <<YAML
apiVersion: crd.projectcalico.org/v1
kind: NetworkPolicy
metadata:
  name: ${var.namespace}-ingress-np
  namespace: ${var.namespace}
spec:
  order: 10
  selector: ${var.selector}
  types:
    - Ingress
  ingress:
    - action: Allow
      protocol: TCP
      source:
        namespaceSelector: kubernetes.io/metadata.name == 'kube-system'
        selector: app.kubernetes.io/name == 'rke2-ingress-nginx'
  YAML
}
