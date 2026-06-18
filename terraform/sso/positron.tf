resource "kubernetes_namespace" "positron" {
  metadata {
    name = var.positron_ns
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
    repoURL: https://profiidev.github.io/helm-charts
    chart: positron
    targetRevision: "*"
    helm:
      releaseName: positron
      valuesObject:
        secret:
          storeName: ${var.cluster_secret_store}
        ingress:
          className: ${var.ingress_class}
          annotations:
            traefik.ingress.kubernetes.io/router.tls.options: ${var.positron_ns}-positron-tls-options@kubernetescrd
            external-dns.alpha.kubernetes.io/ingress-hostname-source: annotation-only
            external-dns.alpha.kubernetes.io/cloudflare-proxied: "true"
            external-dns.alpha.kubernetes.io/hostname: profidev.io
            external-dns.alpha.kubernetes.io/target: cluster.profidev.io
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

  depends_on = [kubernetes_namespace.positron]
}
resource "kubectl_manifest" "positron_tls_options" {
  yaml_body = <<YAML
apiVersion: traefik.io/v1alpha1
kind: TLSOption
metadata:
  name: positron-tls-options
  namespace: ${var.positron_ns}
spec:
  clientAuth:
    clientAuthType: RequireAndVerifyClientCert
    secretNames:
      - ${var.cloudflare_ca_cert_var}
  YAML

  depends_on = [kubernetes_namespace.positron]
}

resource "kubectl_manifest" "positron_egress" {
  yaml_body = <<YAML
apiVersion: crd.projectcalico.org/v1
kind: GlobalNetworkPolicy
metadata:
  name: positron-egress
spec:
  order: 10
  namespaceSelector: kubernetes.io/metadata.name == '${var.positron_ns}'
  selector: app == 'positron'
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

  depends_on = [kubernetes_namespace.positron]
}

resource "null_resource" "wait_for_positron" {
   provisioner "local-exec" {
    command = <<-EOT
      set -euo pipefail

      while [[ $(kubectl get pods -n ${var.positron_ns} -l app=positron -o 'jsonpath={..status.conditions[?(@.type=="Ready")].status}') != "True" ]]; do
        echo "Waiting for Positron to be ready..."
        sleep 5
      done

      echo "Positron is ready!"
    EOT
  }

  depends_on = [kubectl_manifest.positron_app]
}
