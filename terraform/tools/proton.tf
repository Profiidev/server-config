resource "kubernetes_namespace" "proton_ns" {
  metadata {
    name = var.proton_ns
    labels = {
      "${var.cloudflare_cert_label.key}" = var.cloudflare_cert_label.value
      "${var.secret_store_label.key}"    = var.secret_store_label.value
      "${var.cluster_ca_cert_label.key}" = var.cluster_ca_cert_label.value
    }
  }
}

resource "kubectl_manifest" "proton_app" {
  yaml_body = <<YAML
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: proton
  namespace: ${var.argo_ns}
  finalizers:
    - resources-finalizer.argocd.argoproj.io
spec:
  project: default
  source:
    repoURL: https://profiidev.github.io/server-config
    chart: proton
    targetRevision: "*"
    helm:
      releaseName: proton
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
          ingress:
            className: ${var.ingress_class}
            annotations:
              nginx.ingress.kubernetes.io/auth-tls-secret: ${var.proton_ns}/${var.cloudflare_ca_cert_var}
              nginx.ingress.kubernetes.io/auth-tls-verify-client: "on"
              nginx.ingress.kubernetes.io/rewrite-target: "/$1"
            tls:
              - hosts:
                  - profidev.io
                  - "*.profi.dev"
                secretName: ${var.cloudflare_cert_var}
  destination:
    server: https://kubernetes.default.svc
    namespace: ${var.proton_ns}
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

  depends_on = [kubernetes_namespace.proton_ns]
}
