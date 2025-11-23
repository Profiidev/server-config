resource "kubernetes_namespace" "coder" {
  metadata {
    name = var.coder_ns
  }
}

resource "helm_release" "coder" {
  name       = "coder"
  repository = "https://helm.coder.com/v2"
  chart      = "coder"
  version    = "2.28.3"
  namespace  = var.coder_ns

  values = [templatefile("${path.module}/templates/coder.values.tftpl", {
    ingress_class = var.ingress_class
    cert_issuer   = var.cert_issuer_prod
  })]

  depends_on = [kubernetes_namespace.coder]
}

resource "kubectl_manifest" "coder_egress" {
  yaml_body = <<YAML
apiVersion: crd.projectcalico.org/v1
kind: NetworkPolicy
metadata:
  name: coder-egress
  namespace: ${var.coder_ns}
spec:
  order: 10
  namespaceSelector: kubernetes.io/metadata.name == '${var.coder_ns}'
  selector: app.kubernetes.io/instance == 'coder'
  types:
    - Egress
  egress:
    - action: Allow
      protocol: TCP
      destination:
        notNets:
          - 10.0.0.0/8
          - 172.16.0.0/12
          - 192.168.0.0/16
        ports:
          - 443
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
  YAML

  depends_on = [kubernetes_namespace.coder]
}

resource "kubectl_manifest" "coder_workspace_egress" {
  yaml_body = <<YAML
apiVersion: crd.projectcalico.org/v1
kind: GlobalNetworkPolicy
metadata:
  name: coder-workspace-egress
spec:
  order: 10
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

  depends_on = [kubernetes_namespace.coder]
}

resource "kubectl_manifest" "coder_secrets" {
  yaml_body = <<YAML
apiVersion: external-secrets.io/v1
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
      key: tools/coder
  YAML

  depends_on = [kubernetes_namespace.coder]
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

  depends_on = [kubernetes_namespace.coder]
}
