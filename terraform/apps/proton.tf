resource "kubernetes_namespace" "proton" {
  metadata {
    name = var.proton_ns
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
    repoURL: https://profiidev.github.io/helm-charts
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
                secretName: kube-root-ca.crt
          extraVolumeMounts:
            - name: cluster-ca-cert
              readOnly: true
              subPath: ${local.ca_hash}.0
              mountPath: /etc/ssl/certs/${local.ca_hash}.0
          ingress:
            className: ${var.ingress_class}
            annotations:
              nginx.ingress.kubernetes.io/auth-tls-secret: ${var.proton_ns}/${var.cloudflare_ca_cert_var}
              nginx.ingress.kubernetes.io/auth-tls-verify-client: "on"
              traefik.ingress.kubernetes.io/router.middlewares: ${var.proton_ns}-proton@kubernetescrd
            tls:
              - hosts:
                  - profidev.io
                  - "*.profidev.io"
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

  depends_on = [kubernetes_namespace.proton]
}

resource "kubectl_manifest" "proton_middleware" {
  yaml_body = <<YAML
apiVersion: traefik.io/v1alpha1
kind: Middleware
metadata:
  name: proton
  namespace: ${var.proton_ns}
spec:
  stripPrefix:
    prefixes:
      - /backend
  YAML
}
