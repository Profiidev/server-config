data "template_file" "cluster_ca_cert_volume" {
  template = templatefile("${path.module}/templates/cluster-ca-cert-volume.tftpl", {
    cluster_ca_cert = var.cluster_ca_cert_var
  })
}

data "template_file" "cluster_ca_cert_volume_mount" {
  template = templatefile("${path.module}/templates/cluster-ca-cert-volume-mount.tftpl", {
    cluster_ca_cert = var.cluster_ca_cert_var
  })
}

resource "kubernetes_namespace" "secrets_ns" {
  metadata {
    name = var.secrets_ns
    labels = {
      "${var.secret_store_label.key}" = var.secret_store_label.value
    }
  }
}

resource "helm_release" "external_secrets" {
  name       = "external-secrets"
  repository = "https://charts.external-secrets.io"
  chart      = "external-secrets"
  version    = "0.15.0"
  namespace  = var.secrets_ns

  values = [templatefile("${path.module}/templates/external-secrets.values.tftpl", {
    volume       = data.template_file.cluster_ca_cert_volume.rendered
    volume_mount = data.template_file.cluster_ca_cert_volume_mount.rendered
  })]

  depends_on = [
    kubernetes_namespace.secrets_ns,
    kubernetes_secret_v1.cluster_ca_cert_secret
  ]
}

resource "kubectl_manifest" "cluster_secret_store" {
  yaml_body = <<YAML
apiVersion: external-secrets.io/v1beta1
kind: ClusterSecretStore
metadata:
  name: ${var.cluster_secret_store}
spec:
  provider:
    vault:
      server: https://vault.${var.secrets_ns}.svc:8200
      path: kv
      version: v2
      auth:
        tokenSecretRef:
          namespace: ${var.secrets_ns}
          name: ${var.vault_global_token}
          key: ${var.vault_global_token_prop}
  conditions:
    - namespaceSelector:
        matchLabels:
          ${var.secret_store_label.key}: "${var.secret_store_label.value}"
  YAML

  depends_on = [helm_release.external_secrets]
}
