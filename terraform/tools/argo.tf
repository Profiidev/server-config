resource "kubernetes_namespace" "argo" {
  metadata {
    name = var.argo_ns
  }
}

resource "helm_release" "argocd" {
  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = "9.1.4"
  namespace  = var.argo_ns

  values = [templatefile("${path.module}/templates/argocd.values.tftpl", {
    ingress_class = var.ingress_class
    cert_issuer   = var.cert_issuer_prod
  })]

  depends_on = [kubernetes_namespace.argo]
}

module "k8s_api_np_argo" {
  source = "../modules/k8s-api-np"

  namespace = var.argo_ns
  k8s_api   = var.k8s_api

  depends_on = [kubernetes_namespace.argo]
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
      key: tools/argo
  YAML

  depends_on = [kubernetes_namespace.argo]
}

module "external_np_argo" {
  source = "../modules/external-np"

  namespace = var.argo_ns

  depends_on = [kubernetes_namespace.argo]
}
