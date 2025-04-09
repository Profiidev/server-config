resource "kubectl_manifest" "egress" {
  yaml_body = <<YAML
apiVersion: crd.projectcalico.org/v1
kind: NetworkPolicy
metadata:
  name: ${var.name}-egress
  namespace: ${var.metrics_ns}
spec:
  order: 10
  namespaceSelector: kubernetes.io/metadata.name == '${var.metrics_ns}'
  types:
    - Egress
  egress:
    - action: Allow
      protocol: TCP
      destination:
        namespaceSelector: kubernetes.io/metadata.name == '${var.namespace}'
        selector: ${var.selector != null ? var.selector : "app.kubernetes.io/instance == '${var.name}'"}
        ports:
          - ${var.port}
  YAML
}

resource "kubectl_manifest" "prometheus_coredns" {
  yaml_body = <<YAML
apiVersion: crd.projectcalico.org/v1
kind: NetworkPolicy
metadata:
  name: prometheus-${var.name}
  namespace: ${var.namespace}
spec:
  order: 10
  namespaceSelector: kubernetes.io/metadata.name == '${var.namespace}'
  selector: ${var.selector != null ? var.selector : "app.kubernetes.io/instance == '${var.name}'"}
  types:
    - Ingress
  ingress:
    - action: Allow
      protocol: TCP
      destination:
        ports:
          - ${var.port}
      source:
        namespaceSelector: kubernetes.io/metadata.name == '${var.metrics_ns}'
  YAML
}
