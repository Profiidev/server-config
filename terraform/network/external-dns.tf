resource "kubernetes_namespace" "external-dns" {
  metadata {
    name = var.external_dns_ns
  }
}

resource "helm_release" "external-dns" {
  name       = "external-dns"
  repository = "https://kubernetes-sigs.github.io/external-dns"
  chart      = "external-dns"
  namespace  = kubernetes_namespace.external-dns.metadata[0].name
  version    = "1.21.1"

  values = [
    templatefile("${path.module}/templates/external-dns.values.tftpl", {
    })
  ]

  depends_on = [kubectl_manifest.external_dns_secrets]
}

resource "kubectl_manifest" "external_dns_secrets" {
  yaml_body = <<YAML
apiVersion: external-secrets.io/v1
kind: ExternalSecret
metadata:
  name: external-dns
  namespace: ${kubernetes_namespace.external-dns.metadata[0].name}
spec:
  refreshInterval: 5m
  secretStoreRef:
    name: ${var.cluster_secret_store}
    kind: ClusterSecretStore
  target:
    name: external-dns
  dataFrom:
  - extract:
      key: certs/cert-manager
  YAML
}

module "external_np_external_dns" {
  source = "../modules/external-np"

  namespace = var.external_dns_ns

  depends_on = [kubernetes_namespace.external-dns]
}
