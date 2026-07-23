resource "kubernetes_namespace" "sure" {
  metadata {
    name = var.sure_ns
  }
}

resource "helm_release" "sure" {
  name       = "sure"
  repository = "https://we-promise.github.io/sure"
  chart      = "sure"
  version    = "0.7.2"
  namespace  = var.sure_ns

  values = [templatefile("${path.module}/templates/sure.values.tftpl", {
    ingress_class       = var.ingress_class
    cloudflare_cert_var = var.cloudflare_cert_var
    namespace           = var.sure_ns
  })]

  depends_on = [kubernetes_namespace.sure]
}

resource "kubectl_manifest" "sure_secrets" {
  yaml_body = <<YAML
apiVersion: external-secrets.io/v1
kind: ExternalSecret
metadata:
  name: sure
  namespace: ${var.sure_ns}
spec:
  refreshInterval: 5m
  secretStoreRef:
    name: ${var.cluster_secret_store}
    kind: ClusterSecretStore
  target:
    name: sure
  dataFrom:
  - extract:
      key: apps/sure
  YAML

  depends_on = [kubernetes_namespace.sure]
}

resource "kubectl_manifest" "sure_tls_options" {
  yaml_body = <<YAML
apiVersion: traefik.io/v1alpha1
kind: TLSOption
metadata:
  name: sure-tls-options
  namespace: ${var.sure_ns}
spec:
  clientAuth:
    clientAuthType: RequireAndVerifyClientCert
    secretNames:
      - ${var.cloudflare_ca_cert_var}
  YAML

  depends_on = [kubernetes_namespace.sure]
}

resource "kubectl_manifest" "sure_egress" {
  yaml_body = <<YAML
apiVersion: crd.projectcalico.org/v1
kind: GlobalNetworkPolicy
metadata:
  name: sure-egress
spec:
  order: 10
  namespaceSelector: kubernetes.io/metadata.name == '${var.sure_ns}'
  selector: app.kubernetes.io/name == 'sure'
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

  depends_on = [kubernetes_namespace.sure]
}
