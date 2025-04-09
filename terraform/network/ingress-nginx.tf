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
      metrics:
        enabled: true
        serviceMonitor:
          additionalLabels:
            release: prometheus
          enabled: true
    tcp:
      25: "stalwart/stalwart:25"
      587: "stalwart/stalwart:587"
      465: "stalwart/stalwart:465"
      993: "stalwart/stalwart:993"
  YAML
}
