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
    repoURL: https://profiidev.github.io/server-config
    chart: positron
    targetRevision: "*"
    helm:
      releaseName: positron
      valuesObject:
        secret:
          storeName: ${var.cluster_secret_store}
        backend:
          extraVolumes:
            - name: cluster-ca-cert
              secret:
                defaultMode: 420
                secretName: cluster-ca-cert
          extraVolumeMounts:
            - name: cluster-ca-cert
              readOnly: true
              subPath: ${var.ca_hash}.0
              mountPath: /etc/ssl/certs/${var.ca_hash}.0
          podLabels:
            ${var.nats_access_label.key}: "${var.nats_access_label.value}"
            ${var.minio_access_label.key}: "${var.minio_access_label.value}"
            ${var.postgres_access_label.key}: "${var.postgres_access_label.value}"
          ingress:
            className: ${var.ingress_class}
            annotations:
              nginx.ingress.kubernetes.io/auth-tls-secret: ${var.positron_ns}/${var.cloudflare_ca_cert_var}
              nginx.ingress.kubernetes.io/auth-tls-verify-client: "on"
              nginx.ingress.kubernetes.io/rewrite-target: "/$1"
            tls:
              - hosts:
                  - profidev.io
                  - "*.profidev.io"
                secretName: ${var.cloudflare_cert_var}

        frontend:
          ingress:
            className: ${var.ingress_class}
            annotations:
              nginx.ingress.kubernetes.io/auth-tls-secret: ${var.positron_ns}/${var.cloudflare_ca_cert_var}
              nginx.ingress.kubernetes.io/auth-tls-verify-client: "on"
            tls:
              - hosts:
                  - profidev.io
                  - "*.profidev.io"
                secretName: ${var.cloudflare_cert_var}

  destination:
    server: https://kubernetes.default.svc
    namespace: ${var.positron_ns}
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
