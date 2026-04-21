resource "kubernetes_namespace" "radar" {
  metadata {
    name = var.radar_ns
  }
}

resource "helm_release" "radar" {
  name       = "radar"
  repository = "https://skyhook-io.github.io/helm-charts"
  chart      = "radar"
  version    = "1.5.1"
  namespace  = var.radar_ns

  values = [templatefile("${path.module}/templates/radar.values.tftpl", {
    ingress_class = var.ingress_class
    cloudflare_cert_var = var.cloudflare_cert_var
    namespace     = var.radar_ns
  })]

  depends_on = [kubernetes_namespace.radar]
}

resource "kubernetes_namespace" "caretta" {
  metadata {
    name = var.caretta_ns
  }
}

resource "helm_release" "caretta" {
  name       = "caretta"
  repository = "https://helm.groundcover.com"
  chart      = "caretta"
  version    = "0.0.16"
  namespace  = var.caretta_ns

  values = [templatefile("${path.module}/templates/caretta.values.tftpl", {
  })]

  depends_on = [kubernetes_namespace.caretta]
}

module "k8s_api_np_radar" {
  source = "../modules/k8s-api-np"

  namespace = var.radar_ns
  k8s_api   = var.k8s_api

  depends_on = [kubernetes_namespace.radar]
}

resource "kubectl_manifest" "radar_secrets" {
  yaml_body = <<YAML
apiVersion: external-secrets.io/v1
kind: ExternalSecret
metadata:
  name: radar
  namespace: ${var.radar_ns}
spec:
  refreshInterval: 5m
  secretStoreRef:
    name: ${var.cluster_secret_store}
    kind: ClusterSecretStore
  target:
    name: radar
  dataFrom:
  - extract:
      key: tools/radar
  YAML
  
  depends_on = [kubernetes_namespace.radar]
}

resource "kubectl_manifest" "radar_oidc_middleware" {
  yaml_body = <<YAML
apiVersion: traefik.io/v1alpha1
kind: Middleware
metadata:
  name: radar
  namespace: ${var.radar_ns}
spec:
  plugin:
    traefik-oidc-auth:
      Secret: "urn:k8s:secret:radar:secret"
      Provider:
        ClientId: "urn:k8s:secret:radar:client-id"
        ClientSecret: "urn:k8s:secret:radar:client-secret"
        Url: "https://profidev.io/backend/oauth"
      Scopes:
        - "openid"
        - "profile"
        - "email"
  YAML
  
  depends_on = [kubernetes_namespace.radar]
}

resource "kubectl_manifest" "radar_tls_options" {
  yaml_body = <<YAML
apiVersion: traefik.io/v1alpha1
kind: TLSOption
metadata:
  name: radar-tls-options
  namespace: ${var.radar_ns}
spec:
  clientAuth:
    clientAuthType: RequireAndVerifyClientCert
    secretNames:
      - ${var.cloudflare_ca_cert_var}
  YAML
  
  depends_on = [kubernetes_namespace.radar]
}

resource "kubernetes_service" "caretta" {
  metadata {
    name      = "caretta"
    namespace = var.caretta_ns
    labels = {
      app = "caretta"
      "app.kubernetes.io/name"    = "caretta"
      "app.kubernetes.io/instance" = "caretta"
    }
  }

  spec {
    selector = {
      app = "caretta"
      "app.kubernetes.io/name"    = "caretta"
      "app.kubernetes.io/instance" = "caretta"
    }

    port {
      name        = "prom-metrics"
      port        = 7117
      target_port = "prom-metrics"
      protocol    = "TCP"
    }

    type = "ClusterIP"
  }
  
  depends_on = [kubernetes_namespace.caretta]
}

resource "kubectl_manifest" "caretta_service_monitor" {
  yaml_body = <<YAML
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: caretta
  labels:
    app.kubernetes.io/name: caretta
spec:
  selector:
    matchLabels:
      app: caretta
  namespaceSelector:
    matchNames:
      - ${var.radar_ns}
  endpoints:
    - port: prom-metrics
      path: /metrics
      interval: 60s
  YAML

  depends_on = [kubernetes_namespace.caretta]
}
