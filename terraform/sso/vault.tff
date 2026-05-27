locals {
  vault_exec = "kubectl exec -i vault-0 -n ${var.secrets_ns} -- vault"
}

resource "null_resource" "vault_oidc_policy" {
  provisioner "local-exec" {
    command = <<-EOT
      set -euo pipefail

      kubectl exec vault-0 -n ${var.secrets_ns} -- vault login ${local.vault_token}
      cat ${path.module}/vault-policy.hcl | ${local.vault_exec} policy write admin -
    EOT
  }
}

resource "null_resource" "vault_oidc_group" {
  provisioner "local-exec" {
    command = <<-EOT
      set -euo pipefail

      ${local.vault_exec} write identity/group name="Vault Admin" type="external" policies="admin"
    EOT
  }

  depends_on = [null_resource.vault_oidc_policy]
}

resource "null_resource" "vault_oidc_client" {
  provisioner "local-exec" {
    command = <<-EOT
      set -euo pipefail

      GROUP_ID=$(${local.positron_exec} group create "Vault Admin")
      OUTPUT=$(${local.positron_exec} oauth-client create Vault https://vault.profidev.io/ui/vault/auth/oidc/oidc/callback openid,profile,email "$GROUP_ID")

      CLIENT_ID=$(echo "$OUTPUT" | jq -r '.id')
      CLIENT_SECRET=$(echo "$OUTPUT" | jq -r '.secret')
      echo "{\"client_id\": \"$CLIENT_ID\", \"client_secret\": \"$CLIENT_SECRET\"}" > ${path.module}/vault_oidc_client.json
    EOT
  }

  depends_on = [null_resource.wait_for_positron]
}

data "local_sensitive_file" "vault_status" {
  filename   = "${path.module}/vault_oidc_client.json"
  depends_on = [null_resource.vault_oidc_client]
}

locals {
  vault_oidc_client = jsondecode(data.local_sensitive_file.vault_status.content)
  vault_client_id = local.vault_oidc_client.client_id
  vault_client_secret = local.vault_oidc_client.client_secret
}

resource "null_resource" "vault_oidc_config" {
  provisioner "local-exec" {
    command = <<-EOT
      set -euo pipefail

      ${local.vault_exec} auth enable oidc

      ${local.vault_exec} write auth/oidc/config \
        oidc_client_id="${local.vault_client_id}" \
        oidc_client_secret="${local.vault_client_secret}" \
        default_role="default" \
        oidc_discovery_url="https://profidev.io/api/oauth"

      ${local.vault_exec} write auth/oidc/role/default \
        bound_audiences="${local.vault_client_id}" \
        allowed_redirect_uris="https://vault.profidev.io/ui/vault/auth/oidc/oidc/callback" \
        allowed_redirect_uris="http://localhost:8250/oidc/callback" \
        user_claim="email" \
        group_claim="groups" \
        token_policies="default" \
        oidc_scopes="openid,profile,email"
    EOT
  }

  depends_on = [null_resource.vault_oidc_group]
}

resource "null_resource" "vault_oidc_group_alias" {
  provisioner "local-exec" {
    command = <<-EOT
      set -euo pipefail

      OIDC_ACCESSOR=$(${local.vault_exec} auth list -format=json | jq -r '.["oidc/"].accessor')
      INTERNAL_GROUP_ID=$(${local.vault_exec} read -format=json identity/group/name/"Vault Admin" | jq -r '.data.id')

      ${local.vault_exec} write identity/group-alias name="Vault Admin" mount_accessor="$OIDC_ACCESSOR" canonical_id="$INTERNAL_GROUP_ID"
    EOT
  }

  depends_on = [null_resource.vault_oidc_config]
}
