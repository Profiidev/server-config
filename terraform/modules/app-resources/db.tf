resource "terraform_data" "app_db" {
  count = var.db_name != null && var.enabled ? 1 : 0

  input = {
    vault_exec = local.vault_exec
    exec = local.db_exec
    db_name = var.db_name
    db_url = "${local.db_url_base}/${var.db_name}?sslmode=disable"
    db_url_var = var.db_url_var
  }

  provisioner "local-exec" {
    command = <<-EOT
      set -euo pipefail

      ${self.input.exec} -c "CREATE DATABASE ${self.input.db_name};"
      ${self.input.vault_exec} ${self.input.db_url_var}="${self.input.db_url}"
    EOT
  }

  provisioner "local-exec" {
    when    = destroy
    command = <<-EOT
      set -euo pipefail

      ${self.input.exec} -c "DROP DATABASE IF EXISTS ${self.input.db_name};"
    EOT
  }

  depends_on = [terraform_data.app_secret]
}
