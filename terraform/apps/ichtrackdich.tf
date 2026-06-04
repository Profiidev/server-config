resource "kubernetes_namespace" "ichtrackdich" {
  metadata {
    name = var.ichtrackdich_ns
  }
}

resource "kubectl_manifest" "ichtrackdich_app" {
  yaml_body = <<YAML
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: ichtrackdich
  namespace: ${var.argo_ns}
  finalizers:
    - resources-finalizer.argocd.argoproj.io
spec:
  project: default
  source:
    repoURL: https://profiidev.github.io/helm-charts
    chart: ichtrackdich
    targetRevision: "*"
    helm:
      releaseName: ichtrackdich
      valuesObject:
        secret:
          storeName: ${var.cluster_secret_store}
        ingress:
          className: ${var.ingress_class}
          host: ichtrackdich.profidev.io
          annotations:
            cert-manager.io/cluster-issuer: ${var.cert_issuer_prod}
          tls:
            - hosts:
                - ichtrackdich.profidev.io
              secretName: ichtrackdich-tls
  destination:
    server: https://kubernetes.default.svc
    namespace: ${var.ichtrackdich_ns}
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

  depends_on = [kubernetes_namespace.ichtrackdich]
}

resource "kubectl_manifest" "ichtrackdich_egress" {
  yaml_body = <<YAML
apiVersion: crd.projectcalico.org/v1
kind: GlobalNetworkPolicy
metadata:
  name: ichtrackdich-egress
spec:
  order: 10
  namespaceSelector: kubernetes.io/metadata.name == '${var.ichtrackdich_ns}'
  selector: app == 'ichtrackdich'
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

  depends_on = [kubernetes_namespace.ichtrackdich]
}
