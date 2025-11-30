resource "kubectl_manifest" "egress" {
  yaml_body = <<YAML
apiVersion: crd.projectcalico.org/v1
kind: NetworkPolicy
metadata:
  name: ${var.namespace}-api-egress
  namespace: ${var.namespace}
spec:
  order: 10
  selector: all()
  types:
    - Egress
  egress:
    - action: Allow
      protocol: TCP
      destination:
        nets:
          - ${var.k8s_api}/32
        ports:
          - 6443
  YAML
}
