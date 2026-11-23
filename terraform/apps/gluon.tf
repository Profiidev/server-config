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

          # --- CI profiles replacing the commit-bot secrets in workflows ---
          # Pinned to workflow files in Profiidev repos, so third-party reusable workflows never match.

          # Lint auto-fix on same-repo PRs (fork PRs get no OIDC token): push fix commits, create check runs.
          [[profiles]]
          name = "lint"
          permissions = { contents = "write", checks = "write", pull_requests = "write" }
          allow_non_branch_write = true
          match = { job_workflow_ref = { regex = 'Profiidev/[^/]+/\.github/workflows/checks\.yml@refs/(pull/\d+/merge|heads/.+)' } }

          # checks-publish / tests-publish run on workflow_run from the default branch only.
          [[profiles]]
          name = "publish"
          permissions = { checks = "write", pull_requests = "write", contents = "read" }
          allow_events = ["workflow_run"]
          match = { event_name = "workflow_run", job_workflow_ref = { regex = 'Profiidev/[^/]+/\.github/workflows/(checks|tests)-publish\.yml@refs/heads/main' } }

          # Release workflow on a version tag dispatches the chart bump to helm-charts.
          [[profiles]]
          name = "chart-bump"
          repositories = ["Profiidev/helm-charts"]
          permissions = { contents = "write" }
          match = { ref_type = "tag", job_workflow_ref = { regex = 'Profiidev/[^/]+/\.github/workflows/release\.yml@refs/tags/v.+' } }

          # Bot automation on pull_request events (auto-merge, tag on merged release PR,
          # commit fixes to a PR branch): write access on the PR merge ref.
          [[profiles]]
          name = "pr-automation"
          permissions = { contents = "write", pull_requests = "write" }
          allow_non_branch_write = true
          match = { event_name = "pull_request", job_workflow_ref = { regex = 'Profiidev/[^/]+/\.github/workflows/(auto-merge-[a-z0-9-]+|create-release|fix-package-json)\.yml@refs/pull/\d+/merge' } }

          # Renovate: main branch runs plus its own bot-PR "edited" runs.
          [[profiles]]
          name = "renovate"
          permissions = { contents = "write", pull_requests = "write", issues = "write", checks = "write", statuses = "write", workflows = "write", vulnerability_alerts = "read" }
          allow_dangerous = true
          allow_non_branch_write = true
          match = { job_workflow_ref = { regex = 'Profiidev/[^/]+/\.github/workflows/renovate\.yml@refs/(heads/main|pull/\d+/merge)' } }

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
