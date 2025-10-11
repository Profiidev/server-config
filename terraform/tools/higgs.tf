resource "kubernetes_namespace" "higgs_ns" {
  metadata {
    name = var.higgs_ns
    labels = {
      "${var.cloudflare_cert_label.key}" = var.cloudflare_cert_label.value
      "${var.secret_store_label.key}"    = var.secret_store_label.value
    }
  }
}

resource "kubectl_manifest" "higgs_app" {
  yaml_body = <<YAML
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: higgs
  namespace: ${var.argo_ns}
  finalizers:
    - resources-finalizer.argocd.argoproj.io
spec:
  project: default
  source:
    repoURL: https://profiidev.github.io/server-config
    chart: higgs
    targetRevision: "*"
    helm:
      releaseName: higgs
      valuesObject:
        frontend:
          ingress:
            className: ${var.ingress_class}
            annotations:
              nginx.ingress.kubernetes.io/auth-tls-secret: ${var.higgs_ns}/${var.cloudflare_ca_cert_var}
              nginx.ingress.kubernetes.io/auth-tls-verify-client: "on"
            tls:
              - hosts:
                  - profidev.io
                  - "*.profidev.io"
                secretName: ${var.cloudflare_cert_var}

  destination:
    server: https://kubernetes.default.svc
    namespace: ${var.higgs_ns}
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

  depends_on = [kubernetes_namespace.higgs_ns]
}
