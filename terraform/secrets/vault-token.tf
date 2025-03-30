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
