resource "kubernetes_namespace" "argo_ns" {
  metadata {
    name = var.argo_ns
    labels = {
      "${var.cloudflare_cert_label.key}" = var.cloudflare_cert_label.value
      "${var.secret_store_label.key}"    = var.secret_store_label.value
    }
  }
}

resource "helm_release" "argocd" {
  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = "7.8.28"
  namespace  = var.argo_ns

  values = [templatefile("${path.module}/templates/argocd.values.tftpl", {
    ingress_class = var.ingress_class
    cert_issuer   = var.cert_issuer_prod
  })]

  depends_on = [kubernetes_namespace.argo_ns]
}

resource "kubectl_manifest" "argo_k8s_api_egress" {
  yaml_body = <<YAML
apiVersion: crd.projectcalico.org/v1
kind: NetworkPolicy
metadata:
  name: k8s-api-egress
  namespace: ${var.argo_ns}
spec:
  order: 10
  types:
    - Egress
  egress:
    - action: Allow
      protocol: TCP
      destination:
        nets:
          - 194.164.200.60/32
        ports:
          - 6443
    - action: Allow
      protocol: TCP
      destination:
        notNets:
          - 10.0.0.0/8
          - 172.16.0.0/12
          - 192.168.0.0/16
        ports:
          - 443
  YAML

  depends_on = [kubernetes_namespace.argo_ns]
}

resource "kubectl_manifest" "argo_ns" {
  yaml_body = <<YAML
apiVersion: crd.projectcalico.org/v1
kind: NetworkPolicy
metadata:
  name: argo-namespace
  namespace: ${var.argo_ns}
spec:
  order: 10
  namespaceSelector: kubernetes.io/metadata.name == '${var.argo_ns}'
  types:
    - Egress
    - Ingress
  egress:
    - action: Allow
      protocol: TCP
      destination:
        namespaceSelector: kubernetes.io/metadata.name == '${var.argo_ns}'
  ingress:
    - action: Allow
      protocol: TCP
      source:
        namespaceSelector: kubernetes.io/metadata.name == '${var.argo_ns}'
  YAML

  depends_on = [kubernetes_namespace.argo_ns]
}

resource "kubectl_manifest" "argo_secret" {
  yaml_body = <<YAML
apiVersion: external-secrets.io/v1
kind: ExternalSecret
metadata:
  name: argo
  namespace: ${var.argo_ns}
spec:
  refreshInterval: 15s
  secretStoreRef:
    name: ${var.cluster_secret_store}
    kind: ClusterSecretStore
  target:
    name: argo
    template:
      metadata:
        labels:
          app.kubernetes.io/part-of: argocd
  dataFrom:
  - extract:
      key: apps/argo
  YAML

  depends_on = [kubernetes_namespace.argo_ns]
}
