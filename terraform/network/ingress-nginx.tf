resource "kubectl_manifest" "ingress_nginx_config" {
  yaml_body = <<YAML
apiVersion: helm.cattle.io/v1
kind: HelmChartConfig
metadata:
  name: rke2-ingress-nginx
  namespace: kube-system
spec:
  valuesContent: |-
    controller:
      ingressClassResource:
        name: ${var.ingress_class}
        enabled: true
        default: true
        controllerValue: "k8s.io/ingress-nginx"
        parameters: {}

      ingressClass: ${var.ingress_class}
      watchIngressWithoutClass: false

      networkPolicy:
        enabled: true
      hostNetwork: true
  YAML
}
