variable "cluster_secret_store" {
  type    = string
  default = "cluster-secret-store"
}

variable "vault_global_token" {
  type    = string
  default = "vault-global-token"
}

variable "vault_global_token_prop" {
  type    = string
  default = "token"
}

variable "secret_store_label" {
  type = object({
    key   = string
    value = string
  })
  default = {
    key   = "secret-store"
    value = "true"
  }
}

variable "secrets_ns" {
  description = "Secrets Namespace"
  type        = string
  default     = "secrets-system"
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

  values = [templatefile("${path.module}/../helm/external-secrets.values.tftpl", {
    volume       = data.template_file.cluster_ca_cert_volume.rendered
    volume_mount = data.template_file.cluster_ca_cert_volume_mount.rendered
  })]

  depends_on = [
    kubernetes_namespace.secrets_ns,
    null_resource.vault_cluster_ca_cert
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
          ${var.secret_store_label.key}: ${var.secret_store_label.value}
  YAML

  depends_on = [helm_release.external_secrets]
}

resource "null_resource" "vault_global_token" {
  triggers = {
    config_hash = sha256(jsonencode(var.secrets_ns))
  }

  provisioner "local-exec" {
    command = <<-EOT
      kubectl exec --stdin=true --tty=true vault-0 -n ${var.secrets_ns} -- vault token create -format=json | \
       jq -r '.auth.client_token | {token: .}' > ${path.module}/../certs/global_token.json
    EOT
  }

  depends_on = [null_resource.vault_initial_unseal]
}

data "external" "vault_global_token_out" {
  program = ["bash", "-c", "cat ${path.module}/../certs/global_token.json"]

  depends_on = [null_resource.vault_global_token]
}

resource "kubernetes_secret_v1" "vault_global_token" {
  metadata {
    name      = var.vault_global_token
    namespace = var.secrets_ns
  }

  data = {
    "${var.vault_global_token_prop}" = data.external.vault_global_token_out.result["token"]
  }

  type = "Opaque"
}
