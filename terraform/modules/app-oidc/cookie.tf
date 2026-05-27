resource "random_password" "cookie_secret" {
  count   = var.cookie_secret && var.enabled ? 1 : 0

  length  = 16
  special = true
}

locals {
  cookie_secret_value = var.cookie_secret && var.enabled ? random_password.cookie_secret[0].result : null
}

resource "terraform_data" "app_cookie_secret" {
  count   = var.cookie_secret && var.enabled ? 1 : 0

  input = {
    vault_exec = local.vault_exec
    cookie_secret_var = var.cookie_secret_var
    cookie_secret_value = local.cookie_secret_value
  }

  provisioner "local-exec" {
    command = <<-EOT
      set -euo pipefail

      ${self.input.vault_exec} ${self.input.cookie_secret_var}='${self.input.cookie_secret_value}'
    EOT
  }

  depends_on = [terraform_data.app_secret]
}
