resource "kubernetes_namespace" "tailscale_ns" {
  metadata {
    name = var.tailscale_ns
    labels = {
      "${var.secret_store_label.key}" = var.secret_store_label.value
    }
  }
}

resource "helm_release" "tailscale" {
  name       = "tailscale"
  repository = "https://pkgs.tailscale.com/helmcharts"
  chart      = "tailscale-operator"
  version    = "1.84.2"
  namespace  = var.tailscale_ns

  values = [templatefile("${path.module}/templates/tailscale.values.tftpl", {
  })]

  depends_on = [kubernetes_namespace.tailscale_ns]
}

resource "kubectl_manifest" "tailscale_secrets" {
  yaml_body = <<YAML
apiVersion: external-secrets.io/v1beta1
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
      key: apps/tailscale
  YAML

  depends_on = [kubernetes_namespace.tailscale_ns]
}

resource "kubectl_manifest" "tailscale_network_policy" {
  yaml_body = <<YAML
apiVersion: crd.projectcalico.org/v1
kind: NetworkPolicy
metadata:
  name: tailscale
  namespace: ${var.tailscale_ns}
spec:
  namespaceSelector: kubernetes.io/metadata.name == '${var.tailscale_ns}'
  types:
    - Egress
    - Ingress
  egress:
    - action: Allow
      protocol: TCP
    - action: Allow
      protocol: UDP
  ingress:
    - action: Allow
      protocol: TCP
    - action: Allow
      protocol: UDP
  YAML

  depends_on = [kubernetes_namespace.tailscale_ns]
}
