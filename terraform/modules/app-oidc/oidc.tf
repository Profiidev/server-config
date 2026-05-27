resource "terraform_data" "app_oidc" {
  count = var.oidc != null && var.enabled ? 1 : 0

  input = {
    exec       = local.positron_exec
    client_name = var.oidc.client_name
    redirect_uri = var.oidc.redirect_uri
    scope = var.oidc.scope
    vault_exec = local.vault_exec
    admin_group = var.oidc.admin_group != null ? var.oidc.admin_group : ""
    client_id_var = var.client_id_var
    client_secret_var = var.client_secret_var
    extra_create = var.extra_oidc_create
    extra_destroy = var.extra_oidc_destroy
  }

  provisioner "local-exec" {
    command = <<-EOT
      set -euo pipefail

      GROUP_ID=$(${self.input.exec} group create "${self.input.client_name}")

      if [ -n "${self.input.admin_group}" ]; then
        ADMIN_GROUP_ID=$(${self.input.exec} group create "${self.input.admin_group}")
      fi

      if [ -n '${self.input.extra_create}' ]; then
        ${self.input.extra_create}
      fi

      if [ -n "${self.input.admin_group}" ]; then
        OUTPUT=$(${self.input.exec} oauth-client create "${self.input.client_name}" ${self.input.redirect_uri} ${self.input.scope} "$GROUP_ID" "$ADMIN_GROUP_ID")
      else
        OUTPUT=$(${self.input.exec} oauth-client create "${self.input.client_name}" ${self.input.redirect_uri} ${self.input.scope} "$GROUP_ID")
      fi

      CLIENT_ID=$(echo "$OUTPUT" | jq -r '.id')
      CLIENT_SECRET=$(echo "$OUTPUT" | jq -r '.secret')

      ${self.input.vault_exec} ${self.input.client_id_var}="$CLIENT_ID" ${self.input.client_secret_var}="$CLIENT_SECRET"
    EOT
  }

  provisioner "local-exec" {
    when    = destroy
    command = <<-EOT
      set -euo pipefail

      if [ -n "${self.input.admin_group}" ]; then
        ${self.input.exec} group delete "${self.input.admin_group}"
      fi
      ${self.input.exec} group delete "${self.input.client_name}"
      ${self.input.exec} oauth-client delete "${self.input.client_name}"

      if [ -n '${self.input.extra_destroy}' ]; then
        ${self.input.extra_destroy}
      fi
    EOT
  }

  depends_on = [terraform_data.app_secret]
}
