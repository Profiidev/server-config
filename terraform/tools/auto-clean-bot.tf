resource "kubernetes_namespace" "auto_clean_bot_ns" {
  metadata {
    name = var.auto_clean_bot_ns
    labels = {
      "${var.secret_store_label.key}"    = var.secret_store_label.value
      "${var.cluster_ca_cert_label.key}" = var.cluster_ca_cert_label.value
      "${var.postgres_access_label.key}" = var.postgres_access_label.value
    }
  }
}

resource "kubectl_manifest" "auto_clean_bot_app" {
  yaml_body = <<YAML
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: auto-clean-bot
  namespace: ${var.argo_ns}
  finalizers:
    - resources-finalizer.argocd.argoproj.io
spec:
  project: default
  source:
    repoURL: https://profiidev.github.io/server-config
    chart: auto-clean-bot
    targetRevision: "*"
    helm:
      releaseName: auto-clean-bot
      valuesObject:
        secret:
          storeName: ${var.cluster_secret_store}
        bot:
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
            ${var.postgres_access_label.key}: "${var.postgres_access_label.value}"

  destination:
    server: https://kubernetes.default.svc
    namespace: ${var.auto_clean_bot_ns}
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

  depends_on = [kubernetes_namespace.auto_clean_bot_ns]
}
