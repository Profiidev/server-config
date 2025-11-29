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
      plugins:
        traefik-oidc-auth:
          moduleName: "github.com/sevensolutions/traefik-oidc-auth"
          version: "v0.17.0"

    providers:
      kubernetesIngressNginx:
        ingressClass: ${var.ingress_class}
        controllerClass: "k8s.io/ingress-nginx"
        watchIngressWithoutClass: false
        ingressClassByName: false
        allowExternalNameServices: true

    metrics:
      prometheus:
        serviceMonitor:
          enabled: true

    ingressRoute:
      dashboard:
        enabled: true
        matchRule: "Host(`traefik.profidev.io`)"
        entryPoints:
          - websecure
        middlewares:
          - name: oidc-traefik
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

resource "kubectl_manifest" "traefik_proxy_secrets" {
  yaml_body = <<YAML
apiVersion: external-secrets.io/v1
kind: ExternalSecret
metadata:
  name: traefik-proxy
  namespace: kube-system
spec:
  refreshInterval: 15s
  secretStoreRef:
    name: ${var.cluster_secret_store}
    kind: ClusterSecretStore
  target:
    name: traefik-proxy
  dataFrom:
  - extract:
      key: tools/traefik-proxy
  YAML
}

resource "kubectl_manifest" "traefik_oidc_middleware" {
  yaml_body = <<YAML
apiVersion: traefik.io/v1alpha1
kind: Middleware
metadata:
  name: oidc-traefik
  namespace: kube-system
spec:
  plugin:
    traefik-oidc-auth:
      Secret: "urn:k8s:secret:traefik-proxy:secret"
      Provider:
        ClientId: "urn:k8s:secret:traefik-proxy:client-id"
        ClientSecret: "urn:k8s:secret:traefik-proxy:client-secret"
        Url: "https://profidev.io/backend/oauth"
      Scopes:
        - "openid"
        - "profile"
        - "email"
  YAML
}
