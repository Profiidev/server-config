resource "terraform_data" "app_secret" {
  count = var.enabled ? 1 : 0

  input = {
    secret_path = var.secret_path
    vault_token = local.vault_token
    secret_ns  = var.secrets_ns
    custom_secrets = var.additional_secrets
    exec = local.vault_exec
  }

  provisioner "local-exec" {
    command = <<-EOT
      set -euo pipefail

      kubectl exec vault-0 -n ${self.input.secret_ns} -- vault login ${self.input.vault_token}
      kubectl exec vault-0 -n ${self.input.secret_ns} -- vault kv put -mount=kv ${self.input.secret_path} dummy="placeholder"
      
      %{ for key, value in self.input.custom_secrets }
      ${self.input.exec} ${key}="${value}"
      %{ endfor }
    EOT
  }

  provisioner "local-exec" {
    when    = destroy
    command = <<-EOT
      set -euo pipefail

      kubectl exec vault-0 -n ${self.input.secret_ns} -- vault login ${self.input.vault_token}
      kubectl exec vault-0 -n ${self.input.secret_ns} -- vault kv metadata delete -mount=kv ${self.input.secret_path}
     EOT
  }
}

resource "terraform_data" "app_remove_dummy" {
  count = var.enabled ? 1 : 0

  input = {
    secret_path = var.secret_path
    secret_ns  = var.secrets_ns
  }

  provisioner "local-exec" {
    command = <<-EOT
      set -euo pipefail

      kubectl exec vault-0 -n ${self.input.secret_ns} -- vault kv patch -mount=kv -remove-data=dummy ${self.input.secret_path}
    EOT
  }

  depends_on = [terraform_data.app_secret]
}
