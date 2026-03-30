resource "kubernetes_namespace" "ichwilldich_sep" {
  metadata {
    name = var.ichwilldich_sep_ns
  }
}

resource "kubectl_manifest" "ichwilldich_sep_app" {
  yaml_body = <<YAML
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: ichwilldich-sep
  namespace: ${var.argo_ns}
  finalizers:
    - resources-finalizer.argocd.argoproj.io
spec:
  project: default
  source:
    repoURL: https://profiidev.github.io/helm-charts
    chart: ichwilldich-sep
    targetRevision: "*"
    helm:
      releaseName: ichwilldich-sep
      valuesObject:
        secret:
          storeName: ${var.cluster_secret_store}
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
          host: sap.profidev.io
          annotations:
            traefik.ingress.kubernetes.io/router.tls.options: ${var.ichwilldich_sep_ns}-ichwilldich-sep-tls-options@kubernetescrd
          tls:
            - hosts:
                - profidev.io
                - "*.profidev.io"
              secretName: ${var.cloudflare_cert_var}
  destination:
    server: https://kubernetes.default.svc
    namespace: ${var.ichwilldich_sep_ns}
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

  depends_on = [kubernetes_namespace.ichwilldich_sep]
}
resource "kubectl_manifest" "ichwilldich_sep_tls_options" {
  yaml_body = <<YAML
apiVersion: traefik.io/v1alpha1
kind: TLSOption
metadata:
  name: ichwilldich-sep-tls-options
  namespace: ${var.ichwilldich_sep_ns}
spec:
  clientAuth:
    clientAuthType: RequireAndVerifyClientCert
    secretNames:
      - ${var.cloudflare_ca_cert_var}
  YAML

  depends_on = [kubernetes_namespace.ichwilldich_sep]
}

resource "kubectl_manifest" "ichwilldich_sep_egress" {
  yaml_body = <<YAML
apiVersion: crd.projectcalico.org/v1
kind: GlobalNetworkPolicy
metadata:
  name: ichwilldich-sep-egress
spec:
  order: 10
  namespaceSelector: kubernetes.io/metadata.name == '${var.ichwilldich_sep_ns}'
  selector: app == 'ichwilldich-sep'
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

  depends_on = [kubernetes_namespace.ichwilldich_sep]
}
