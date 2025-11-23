resource "kubernetes_namespace" "charm" {
  metadata {
    name = var.charm_ns
  }
}

resource "kubectl_manifest" "charm_app" {
  yaml_body = <<YAML
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: charm
  namespace: ${var.argo_ns}
  finalizers:
    - resources-finalizer.argocd.argoproj.io
spec:
  project: default
  source:
    repoURL: https://profiidev.github.io/server-config
    chart: charm
    targetRevision: "*"
    helm:
      releaseName: charm
      valuesObject:
        secret:
          storeName: ${var.cluster_secret_store}
        backend:
          imagePullSecrets:
            - name: ${var.ghcr_profidev}
          extraVolumes:
            - name: cluster-ca-cert
              secret:
                defaultMode: 420
                secretName: kube-root-ca.crt
          extraVolumeMounts:
            - name: cluster-ca-cert
              readOnly: true
              subPath: ${local.ca_hash}.0
              mountPath: /etc/ssl/certs/${local.ca_hash}.0
          ingress:
            className: ${var.ingress_class}
            annotations:
              nginx.ingress.kubernetes.io/auth-tls-secret: ${var.charm_ns}/${var.cloudflare_ca_cert_var}
              nginx.ingress.kubernetes.io/auth-tls-verify-client: "on"
              nginx.ingress.kubernetes.io/rewrite-target: "/$1"
            tls:
              - hosts:
                  - profidev.io
                  - "*.profidev.io"
                secretName: ${var.cloudflare_cert_var}

        frontend:
          imagePullSecrets:
            - name: ${var.ghcr_profidev}
          ingress:
            className: ${var.ingress_class}
            annotations:
              nginx.ingress.kubernetes.io/auth-tls-secret: ${var.charm_ns}/${var.cloudflare_ca_cert_var}
              nginx.ingress.kubernetes.io/auth-tls-verify-client: "on"
            tls:
              - hosts:
                  - profidev.io
                  - "*.profidev.io"
                secretName: ${var.cloudflare_cert_var}

  destination:
    server: https://kubernetes.default.svc
    namespace: ${var.charm_ns}
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

  depends_on = [kubernetes_namespace.charm]
}
