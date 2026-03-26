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
          host: cache.profidev.io
          annotations:
            traefik.ingress.kubernetes.io/router.tls.options: ${var.hibernation_ns}-hibernation-tls-options@kubernetescrd
          tls:
            - hosts:
                - profidev.io
                - "*.profidev.io"
              secretName: ${var.cloudflare_cert_var}
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
resource "kubectl_manifest" "hibernation_tls_options" {
  yaml_body = <<YAML
apiVersion: traefik.io/v1alpha1
kind: TLSOption
metadata:
  name: hibernation-tls-options
  namespace: ${var.hibernation_ns}
spec:
  clientAuth:
    clientAuthType: RequireAndVerifyClientCert
    secretNames:
      - ${var.cloudflare_ca_cert_var}
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
