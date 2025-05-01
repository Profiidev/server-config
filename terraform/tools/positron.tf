resource "kubernetes_namespace" "positron_ns" {
  metadata {
    name = var.positron_ns
    labels = {
      "${var.cloudflare_cert_label.key}" = var.cloudflare_cert_label.value
      "${var.secret_store_label.key}"    = var.secret_store_label.value
      "${var.cluster_ca_cert_label.key}" = var.cluster_ca_cert_label.value
      "${var.minio_access_label.key}"    = var.minio_access_label.value
      "${var.postgres_access_label.key}" = var.postgres_access_label.value
      "${var.nats_access_label.key}"     = var.nats_access_label.value
    }
  }
}

resource "kubectl_manifest" "positron_app" {
  yaml_body = <<YAML
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: positron
  namespace: ${var.argo_ns}
  finalizers:
    - resources-finalizer.argocd.argoproj.io
spec:
  project: default
  source:
    repoURL: https://github.com/Profiidev/server-config
    path: apps/positron
    targetRevision: master
  destination:
    server: https://kubernetes.default.svc
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
      allowEmpty: false
    syncOptions:
      - CreateNamespace=false
      - Validate=true
      - PruneLast=true
      - PrunePropagationPolicy=foreground
  YAML

  depends_on = [kubernetes_namespace.positron_ns]
}

module "oidc_access" {
  source = "../modules/access-policy"

  namespace       = var.positron_ns
  namespace_label = var.oidc_access_label
  selector        = "app == 'positron-backend'"
  port            = 8000
  target_selector = "all()"

  depends_on = [kubernetes_namespace.positron_ns]
}
