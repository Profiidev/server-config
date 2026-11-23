resource "kubernetes_namespace" "gluon" {
  metadata {
    name = var.gluon_ns
  }
}

# GitHub App token broker. The private key lives in Vault at tools/gluon
# (field main-key.pem), see README.md.
resource "kubectl_manifest" "gluon" {
  yaml_body = <<YAML
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: gluon
  namespace: ${var.argo_ns}
  finalizers:
    - resources-finalizer.argocd.argoproj.io
spec:
  project: default
  source:
    repoURL: https://profiidev.github.io/helm-charts
    chart: gluon
    targetRevision: "*"
    helm:
      releaseName: gluon
      valuesObject:
        secret:
          storeName: ${var.cluster_secret_store}
          path: tools/gluon
        metrics:
          serviceMonitor:
            enabled: true
        ingress:
          className: ${var.ingress_class}
          host: gluon.profidev.io
          annotations:
            cert-manager.io/cluster-issuer: ${var.cert_issuer_prod}
            external-dns.kubernetes.io/ingress-hostname-source: annotation-only
            external-dns.kubernetes.io/hostname: gluon.profidev.io
            external-dns.kubernetes.io/target: cluster.profidev.io
          tls:
            - hosts:
                - "gluon.profidev.io"
              secretName: gluon-tls
        # Traefik pods; only used to pick the client IP for the audit log.
        trustedProxies:
          - 10.42.0.0/16
        config: |
          [[issuers]]
          name = "github"
          url = "https://token.actions.githubusercontent.com"
          audience = "github-token-broker"

          # profidev-commit-bot
          [[apps]]
          name = "main"
          client_id = "Iv23liM4eWCXa0R0IMG9"
          keys = [{ source = "file", path = "/run/secrets/gluon/main-key.pem" }]

          # Profiidev
          [defaults]
          self_scope = true
          app = "main"
          owner_ids = [92174452]
          permissions = { contents = "write", metadata = "read", pull_requests = "write" }

          [limits]
          per_repository = "30/min"
          burst = 10
  destination:
    server: https://kubernetes.default.svc
    namespace: ${var.gluon_ns}
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

  depends_on = [kubernetes_namespace.gluon]
}
