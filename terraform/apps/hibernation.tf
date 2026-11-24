resource "kubernetes_namespace" "hibernation" {
  metadata {
    name = var.hibernation_ns
  }
}

resource "kubectl_manifest" "hibernation_cache" {
  yaml_body = <<YAML
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: hibernation
  namespace: ${var.argo_ns}
  finalizers:
    - resources-finalizer.argocd.argoproj.io
spec:
  project: default
  source:
    repoURL: https://profiidev.github.io/helm-charts
    chart: hibernation
    targetRevision: "*"
    helm:
      releaseName: hibernation
      valuesObject:
        secret:
          storeName: ${var.cluster_secret_store}
        metrics:
          enabled: true
          serviceMonitor:
            enabled: true
            # url_path holds raw paths (store hashes, upload ids, scanner junk), collapse to route shapes
            metricRelabelings:
              - sourceLabels: [url_path]
                regex: '/api/nix/([^/]+)/[^/]+\.narinfo'
                targetLabel: url_path
                replacement: '/api/nix/$1/:hash.narinfo'
              - sourceLabels: [url_path]
                regex: '/api/nix/([^/]+)/nar/[^/]+'
                targetLabel: url_path
                replacement: '/api/nix/$1/nar/:file'
              - sourceLabels: [url_path]
                regex: '/api/cache/push/[^/]+/[0-9]+'
                targetLabel: url_path
                replacement: '/api/cache/push/:id/:part'
              - sourceLabels: [url_path]
                regex: '/api/cache/push/[^/:]+'
                targetLabel: url_path
                replacement: '/api/cache/push/:id'
              - sourceLabels: [url_path]
                regex: '(/api/.*/)[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}'
                targetLabel: url_path
                replacement: '$${1}:id'
              # everything outside /api (frontend, static assets, scanner probes); RE2 has no lookahead
              - sourceLabels: [url_path]
                regex: '/([^a].*|a([^p].*)?|ap([^i].*)?|api([^/].*)?)'
                targetLabel: url_path
                replacement: '/:other'
        ingress:
          className: ${var.ingress_class}
          host: cache.profidev.io
          annotations:
            cert-manager.io/cluster-issuer: ${var.cert_issuer_prod}
            external-dns.kubernetes.io/ingress-hostname-source: annotation-only
            external-dns.kubernetes.io/hostname: cache.profidev.io,*.cache.profidev.io
            external-dns.kubernetes.io/target: cluster.profidev.io
          # exact and wildcard hosts need separate single-host tls entries, else
          # Traefik mis-binds the apex cert and serves the *.profidev.io fallback
          tls:
            - hosts:
                - "cache.profidev.io"
              secretName: cache-tls
            - hosts:
                - "*.cache.profidev.io"
              secretName: cache-wildcard-tls
  destination:
    server: https://kubernetes.default.svc
    namespace: ${var.hibernation_ns}
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

  depends_on = [kubernetes_namespace.hibernation]
}

resource "kubectl_manifest" "hibernation_egress" {
  yaml_body = <<YAML
apiVersion: crd.projectcalico.org/v1
kind: GlobalNetworkPolicy
metadata:
  name: hibernation-egress
spec:
  order: 10
  namespaceSelector: kubernetes.io/metadata.name == '${var.hibernation_ns}'
  selector: app == 'hibernation'
  types:
    - Egress
  egress:
    - action: Allow
      protocol: TCP
      destination:
        ports:
          - 443
          - 587
          - 465
  YAML

  depends_on = [kubernetes_namespace.hibernation]
}
