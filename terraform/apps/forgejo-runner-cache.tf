resource "kubectl_manifest" "forgejo_runner_cache" {
  yaml_body = <<YAML
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: forgejo-runner-cache
  namespace: ${var.argo_ns}
  finalizers:
    - resources-finalizer.argocd.argoproj.io
spec:
  project: default
  source:
    repoURL: https://profiidev.github.io/helm-charts
    chart: forgejo-runner-s3-cache
    targetRevision: "*"
    helm:
      releaseName: forgejo-runner-cache
      valuesObject:
        secret:
          storeName: ${var.cluster_secret_store}
  destination:
    server: https://kubernetes.default.svc
    namespace: ${var.forgejo_ns}
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

  depends_on = [kubernetes_namespace.forgejo]
}
