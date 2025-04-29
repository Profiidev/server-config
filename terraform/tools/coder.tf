resource "kubernetes_namespace" "coder_ns" {
  metadata {
    name = var.coder_ns
    labels = {
      "${var.secret_store_label.key}"    = var.secret_store_label.value
      "${var.postgres_access_label.key}" = var.postgres_access_label.value
    }
  }
}

resource "helm_release" "coder" {
  name       = "coder"
  repository = "https://helm.coder.com/v2"
  chart      = "coder"
  version    = "2.21.0"
  namespace  = var.coder_ns

  values = [templatefile("${path.module}/templates/coder.values.tftpl", {
    ingress_class               = var.ingress_class
    cert_issuer                 = var.cert_issuer_prod
    postgres_access_label       = var.postgres_access_label.key
    postgres_access_label_value = var.postgres_access_label.value
  })]

  depends_on = [kubernetes_namespace.coder_ns]
}

resource "kubectl_manifest" "coder_secrets" {
  yaml_body = <<YAML
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: coder
  namespace: ${var.coder_ns}
spec:
  refreshInterval: 15s
  secretStoreRef:
    name: ${var.cluster_secret_store}
    kind: ClusterSecretStore
  target:
    name: coder
  dataFrom:
  - extract:
      key: apps/coder
  YAML

  depends_on = [kubernetes_namespace.coder_ns]
}

resource "kubectl_manifest" "coder_egress" {
  yaml_body = <<YAML
apiVersion: crd.projectcalico.org/v1
kind: GlobalNetworkPolicy
metadata:
  name: coder-egress
spec:
  namespaceSelector: kubernetes.io/metadata.name == '${var.coder_ns}'
  selector: app.kubernetes.io/instance == 'coder'
  types:
    - Egress
  egress:
    - action: Allow
      protocol: TCP
      destination:
        ports:
          - 443
        domains:
          - api.github.com
          - github.com
          - profidev.io
    - action: Allow
      protocol: TCP
      destination:
        nets:
          - 194.164.200.60/32
        ports:
          - 6443
    - action: Allow
      protocol: UDP
      destination:
        ports:
          - 19302
        domains:
          - "*.l.google.com"
  YAML

  depends_on = [kubernetes_namespace.positron_ns]
}

resource "kubectl_manifest" "coder_workspace_egress" {
  yaml_body = <<YAML
apiVersion: crd.projectcalico.org/v1
kind: GlobalNetworkPolicy
metadata:
  name: coder-workspace-egress
spec:
  namespaceSelector: kubernetes.io/metadata.name == '${var.coder_ns}'
  selector: app.kubernetes.io/name == 'coder-workspace'
  types:
    - Egress
  egress:
    - action: Allow
      protocol: TCP
    - action: Allow
      protocol: UDP
  YAML

  depends_on = [kubernetes_namespace.positron_ns]
}

resource "kubectl_manifest" "coder_ns" {
  yaml_body = <<YAML
apiVersion: crd.projectcalico.org/v1
kind: NetworkPolicy
metadata:
  name: coder-namespace
  namespace: ${var.coder_ns}
spec:
  order: 10
  namespaceSelector: kubernetes.io/metadata.name == '${var.coder_ns}'
  types:
    - Ingress
    - Egress
  egress:
    - action: Allow
      protocol: TCP
      destination:
        namespaceSelector: kubernetes.io/metadata.name == '${var.coder_ns}'
  ingress:
    - action: Allow
      protocol: TCP
      source:
        namespaceSelector: kubernetes.io/metadata.name == '${var.coder_ns}'
  YAML

  depends_on = [kubernetes_namespace.coder_ns]
}

resource "kubectl_manifest" "coder_pod_monitor" {
  yaml_body = <<YAML
apiVersion: monitoring.coreos.com/v1
kind: PodMonitor
metadata:
  name: coder
  namespace: ${var.coder_ns}
spec:
  selector:
    matchLabels:
      app.kubernetes.io/name: coder
  podMetricsEndpoints:
    - port: prometheus-http
      interval: 60s
      scrapeTimeout: 10s
  YAML

  depends_on = [kubernetes_namespace.coder_ns]
}
