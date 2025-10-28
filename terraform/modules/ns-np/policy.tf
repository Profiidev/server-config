resource "kubectl_manifest" "egress" {
  yaml_body = <<YAML
apiVersion: crd.projectcalico.org/v1
kind: NetworkPolicy
metadata:
  name: ${var.namespace}-internal-traffic
  namespace: ${var.namespace}
spec:
  order: 10
  namespaceSelector: kubernetes.io/metadata.name == '${var.namespace}'
  types:
    - Ingress
    - Egress
  ingress:
    - action: Allow
      protocol: TCP
      source:
        namespaceSelector: kubernetes.io/metadata.name == '${var.namespace}'
  egress:
    - action: Allow
      protocol: TCP
      destination:
        namespaceSelector: kubernetes.io/metadata.name == '${var.namespace}'
  YAML
}
