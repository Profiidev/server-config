resource "kubernetes_namespace" "tailscale" {
  metadata {
    name = var.tailscale_ns
  }
}

resource "helm_release" "tailscale" {
  name       = "tailscale"
  repository = "https://pkgs.tailscale.com/helmcharts"
  chart      = "tailscale-operator"
  version    = "1.90.8"
  namespace  = var.tailscale_ns

  values = [templatefile("${path.module}/templates/tailscale.values.tftpl", {
  })]

  depends_on = [kubernetes_namespace.tailscale]
}

resource "kubectl_manifest" "tailscale_secrets" {
  yaml_body = <<YAML
apiVersion: external-secrets.io/v1
kind: ExternalSecret
metadata:
  name: operator-oauth
  namespace: ${var.tailscale_ns}
spec:
  refreshInterval: 15s
  secretStoreRef:
    name: ${var.cluster_secret_store}
    kind: ClusterSecretStore
  target:
    name: operator-oauth
  dataFrom:
  - extract:
      key: tools/tailscale
  YAML

  depends_on = [kubernetes_namespace.tailscale]
}

resource "kubectl_manifest" "tailscale_egress" {
  yaml_body = <<YAML
apiVersion: crd.projectcalico.org/v1
kind: NetworkPolicy
metadata:
  name: tailscale
  namespace: ${var.tailscale_ns}
spec:
  order: 10
  namespaceSelector: kubernetes.io/metadata.name == '${var.tailscale_ns}'
  types:
    - Egress
    - Ingress
  egress:
    - action: Allow
  ingress:
    - action: Allow
  YAML

  depends_on = [kubernetes_namespace.tailscale]
}

resource "kubectl_manifest" "tailscale_ingress" {
  yaml_body = <<YAML
apiVersion: crd.projectcalico.org/v1
kind: GlobalNetworkPolicy
metadata:
  name: tailscale-ingress
spec:
  order: 30
  types:
    - Ingress
  ingress:
    - action: Allow
      source:
        namespaceSelector: kubernetes.io/metadata.name == '${var.tailscale_ns}'
  YAML

  depends_on = [kubernetes_namespace.tailscale]
}

resource "kubectl_manifest" "tailscale_crd" {
  yaml_body = <<YAML
apiVersion: tailscale.com/v1alpha1
kind: Connector
metadata:
  name: tailscale-connector
  namespace: ${var.tailscale_ns}
spec:
  hostname: "ubuntu"
  exitNode: true
  subnetRouter:
    advertiseRoutes:
      - "10.42.0.0/16"
      - "10.43.0.0/16"
  YAML

  depends_on = [kubernetes_namespace.tailscale, helm_release.tailscale]
}
