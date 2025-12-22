resource "kubernetes_namespace" "nextcloud" {
  metadata {
    name = var.nextcloud_ns
  }
}

resource "helm_release" "nextcloud" {
  name       = "nextcloud"
  repository = "https://nextcloud.github.io/helm"
  chart      = "nextcloud"
  version    = "8.6.0"
  namespace  = var.nextcloud_ns

  values = [templatefile("${path.module}/templates/nextcloud.values.tftpl", {
    ingress_class = var.ingress_class
    cert_issuer   = var.cert_issuer_prod
    storage_class = var.storage_class
    ca_hash       = local.ca_hash
    k8s_api       = var.k8s_api
    namespace     = var.nextcloud_ns
  })]

  depends_on = [kubernetes_namespace.nextcloud]
}

resource "kubectl_manifest" "nextcloud_secret" {
  yaml_body = <<YAML
apiVersion: external-secrets.io/v1
kind: ExternalSecret
metadata:
  name: nextcloud
  namespace: ${var.nextcloud_ns}
spec:
  refreshInterval: 5m
  secretStoreRef:
    name: ${var.cluster_secret_store}
    kind: ClusterSecretStore
  target:
    name: nextcloud
  dataFrom:
  - extract:
      key: apps/nextcloud
  YAML

  depends_on = [kubernetes_namespace.nextcloud]
}

resource "kubectl_manifest" "nextcloud_egress" {
  yaml_body = <<YAML
apiVersion: crd.projectcalico.org/v1
kind: GlobalNetworkPolicy
metadata:
  name: nextcloud-egress
spec:
  order: 10
  namespaceSelector: kubernetes.io/metadata.name == '${var.nextcloud_ns}'
  selector: app.kubernetes.io/instance == 'nextcloud'
  types:
    - Egress
  egress:
    - action: Allow
      protocol: TCP
      destination:
        ports:
          - 443
          - 587
          - 465
  YAML

  depends_on = [kubernetes_namespace.nextcloud]
}

resource "kubectl_manifest" "nextcloud_middleware" {
  yaml_body = <<YAML
apiVersion: traefik.io/v1alpha1
kind: Middleware
metadata:
  name: nextcloud
  namespace: ${var.nextcloud_ns}
spec:
  headers:
    customResponseHeaders:
      Strict-Transport-Security: "max-age=15552000; includeSubDomains; preload"
YAML

  depends_on = [kubernetes_namespace.nextcloud]
}

resource "kubectl_manifest" "nextcloud_middleware_buffering" {
  yaml_body = <<YAML
apiVersion: traefik.io/v1alpha1
kind: Middleware
metadata:
  name: nextcloud-buffering
  namespace: ${var.nextcloud_ns}
spec:
  buffering:
    maxRequestBodyBytes: 536870912 # 512MB
YAML

  depends_on = [kubernetes_namespace.nextcloud]
}
