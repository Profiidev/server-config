resource "kubectl_manifest" "traefik_config" {
  yaml_body = <<YAML
apiVersion: helm.cattle.io/v1
kind: HelmChartConfig
metadata:
  name: rke2-traefik
  namespace: kube-system
spec:
  valuesContent: |-
    experimental:
      fastProxy:
        enabled: true

    providers:
      kubernetesIngressNginx:
        ingressClass: ${var.ingress_class}
        controllerClass: "k8s.io/ingress-nginx"
        watchIngressWithoutClass: false
        ingressClassByName: false

    metrics:
      prometheus:
        serviceMonitor:
          enabled: true
  YAML
}

resource "kubectl_manifest" "traefik_crowdsec" {
  yaml_body = <<YAML
apiVersion: traefik.io/v1alpha1
kind: Middleware
metadata:
  name: bouncer
  namespace: kube-system
spec:
  plugin:
    bouncer:
      enabled: true
      crowdsecMode: stream
      crowdsecLapiScheme: https
      crowdsecLapiHost: "crowdsec-service.crowdsec.svc.cluster.local:8080"
      corwdsecLapiKey: ${random_password.bouncer_key.result}
  YAML
}
