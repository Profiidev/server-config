resource "kubernetes_namespace" "secrets" {
  metadata {
    name = var.secrets_ns
  }
}

resource "helm_release" "external_secrets" {
  name       = "external-secrets"
  repository = "https://charts.external-secrets.io"
  chart      = "external-secrets"
  version    = "0.20.4"
  namespace  = var.secrets_ns

  values = [templatefile("${path.module}/templates/external-secrets.values.tftpl", {
  })]

  depends_on = [
    kubernetes_namespace.secrets,
    kubernetes_secret_v1.cluster_ca_cert_secret
  ]
}

resource "kubectl_manifest" "cluster_secret_store" {
  yaml_body = <<YAML
apiVersion: external-secrets.io/v1
kind: ClusterSecretStore
metadata:
  name: ${var.cluster_secret_store}
spec:
  provider:
    vault:
      server: https://${var.vault_svc}.${var.secrets_ns}.svc:8200
      path: kv
      version: v2
      auth:
        tokenSecretRef:
          namespace: ${var.secrets_ns}
          name: ${var.vault_global_token}
          key: ${var.vault_global_token_prop}
  conditions:
    - namespaceSelector:
        matchLabels: {}
  YAML

  depends_on = [helm_release.external_secrets]
}

module "ns_np_secrets" {
  source = "../modules/ns-np"

  namespace = var.secrets_ns

  depends_on = [kubernetes_namespace.secrets]
}
