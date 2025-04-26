resource "kubectl_manifest" "nats_ingress" {
  yaml_body = <<YAML
apiVersion: crd.projectcalico.org/v1
kind: NetworkPolicy
metadata:
  name: ${var.namespace}-ingress
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
        namespaceSelector: ${var.namespace_label.key} == '${var.namespace_label.value}'
      destination:
        ports:
          - ${var.port}
  YAML
}

resource "kubectl_manifest" "nats_egress" {
  yaml_body = <<YAML
apiVersion: crd.projectcalico.org/v1
kind: GlobalNetworkPolicy
metadata:
  name: ${var.namespace}-egress
spec:
  namespaceSelector: ${var.namespace_label.key} == '${var.namespace_label.value}'
  selector: ${var.namespace_label.key} == '${var.namespace_label.value}'${var.target_selector != "" ? " && ${var.target_selector}" : ""}
  types:
    - Egress
  egress:
    - action: Allow
      protocol: TCP
      destination:
        namespaceSelector: kubernetes.io/metadata.name == '${var.namespace}'
        selector: ${var.selector}
        ports:
          - ${var.port}
  YAML
}
