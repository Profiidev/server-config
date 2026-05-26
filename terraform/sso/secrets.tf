resource "random_password" "cookie_secret" {
  length  = 16
  special = true
}

locals {
  positron_exec = "kubectl exec -n ${var.positron_ns} deploy/positron -- positron"
  cookie_secret = random_password.cookie_secret.result
  oidc_base_config = "OIDC_ENABLED=\"true\" OIDC_ISSUER=\"https://profidev.io/api/oauth\" OIDC_SCOPES=\"openid email profile image\""
}

resource "null_resource" "longhorn_proxy_secrets" {
  provisioner "local-exec" {
    command = <<-EOT
      set -euo pipefail

      GROUP_ID=$(${local.positron_exec} group create Longhorn)
      OUTPUT=$(${local.positron_exec} oauth-client create Longhorn https://longhorn.profidev.io/oidc/callback openid,profile,email "$GROUP_ID")

      CLIENT_ID=$(echo "$OUTPUT" | jq -r '.id')
      CLIENT_SECRET=$(echo "$OUTPUT" | jq -r '.secret')

      kubectl exec vault-0 -n ${var.secrets_ns} -- vault login ${local.vault_token}
      kubectl exec vault-0 -n ${var.secrets_ns} -- vault kv put -mount=kv tools/longhorn-proxy client-id="$CLIENT_ID" client-secret="$CLIENT_SECRET" secret='${local.cookie_secret}'
    EOT
  }

  depends_on = [null_resource.wait_for_positron]
}

resource "null_resource" "alloy_proxy_secrets" {
  provisioner "local-exec" {
    command = <<-EOT
      set -euo pipefail

      GROUP_ID=$(${local.positron_exec} group create Alloy)
      OUTPUT=$(${local.positron_exec} oauth-client create Alloy https://alloy.profidev.io/oidc/callback openid,profile,email "$GROUP_ID")

      CLIENT_ID=$(echo "$OUTPUT" | jq -r '.id')
      CLIENT_SECRET=$(echo "$OUTPUT" | jq -r '.secret')

      kubectl exec vault-0 -n ${var.secrets_ns} -- vault login ${local.vault_token}
      kubectl exec vault-0 -n ${var.secrets_ns} -- vault kv put -mount=kv apps/alloy-proxy client-id="$CLIENT_ID" client-secret="$CLIENT_SECRET" secret='${local.cookie_secret}'
    EOT
  }

  depends_on = [null_resource.wait_for_positron]
}

resource "null_resource" "traefik_proxy_secrets" {
  provisioner "local-exec" {
    command = <<-EOT
      set -euo pipefail

      GROUP_ID=$(${local.positron_exec} group create Traefik)
      OUTPUT=$(${local.positron_exec} oauth-client create Traefik https://traefik.profidev.io/oidc/callback openid,profile,email "$GROUP_ID")

      CLIENT_ID=$(echo "$OUTPUT" | jq -r '.id')
      CLIENT_SECRET=$(echo "$OUTPUT" | jq -r '.secret')

      kubectl exec vault-0 -n ${var.secrets_ns} -- vault login ${local.vault_token}
      kubectl exec vault-0 -n ${var.secrets_ns} -- vault kv put -mount=kv tools/traefik-proxy client-id="$CLIENT_ID" client-secret="$CLIENT_SECRET" secret='${local.cookie_secret}'
    EOT
  }

  depends_on = [null_resource.wait_for_positron]
}

resource "null_resource" "radar_proxy_secrets" {
  provisioner "local-exec" {
    command = <<-EOT
      set -euo pipefail

      GROUP_ID=$(${local.positron_exec} group create Radar)
      OUTPUT=$(${local.positron_exec} oauth-client create Radar https://radar.profidev.io/oidc/callback openid,profile,email "$GROUP_ID")

      CLIENT_ID=$(echo "$OUTPUT" | jq -r '.id')
      CLIENT_SECRET=$(echo "$OUTPUT" | jq -r '.secret')

      kubectl exec vault-0 -n ${var.secrets_ns} -- vault login ${local.vault_token}
      kubectl exec vault-0 -n ${var.secrets_ns} -- vault kv put -mount=kv tools/radar client-id="$CLIENT_ID" client-secret="$CLIENT_SECRET" secret='${local.cookie_secret}'
    EOT
  }

  depends_on = [null_resource.wait_for_positron]
}

resource "null_resource" "forgejo_secrets" {
  provisioner "local-exec" {
    command = <<-EOT
      set -euo pipefail

      GROUP_ID=$(${local.positron_exec} group create Forgejo)
      OUTPUT=$(${local.positron_exec} oauth-client create Forgejo https://git.profidev.io/oidc/callback openid,profile,email "$GROUP_ID")

      CLIENT_ID=$(echo "$OUTPUT" | jq -r '.id')
      CLIENT_SECRET=$(echo "$OUTPUT" | jq -r '.secret')

      cd ${path.module}
      mkdir -p ../storage/certs/forgejo
      if [ ! -f ../storage/certs/forgejo/ssh_key ]; then
        ssh-keygen -t ed25519 -f ../storage/certs/forgejo/ssh_key -N ""
      fi
      PRIVATE_KEY=$(cat ../storage/certs/forgejo/ssh_key)

      kubectl exec vault-0 -n ${var.secrets_ns} -- vault login ${local.vault_token}
      kubectl exec vault-0 -n ${var.secrets_ns} -- vault kv put -mount=kv tools/forgejo key="$CLIENT_ID" secret="$CLIENT_SECRET" privateKey="$PRIVATE_KEY"
    EOT
  }

  depends_on = [null_resource.wait_for_positron]
}

resource "null_resource" "argo_cd_secrets" {
  provisioner "local-exec" {
    command = <<-EOT
      set -euo pipefail

      GROUP_ID=$(${local.positron_exec} group create ArgoCD)
      ADMIN_GROUP_ID=$(${local.positron_exec} group create "ArgoCD Admin")
      OUTPUT=$(${local.positron_exec} oauth-client create ArgoCD https://argocd.profidev.io/oidc/callback openid,profile,email "$GROUP_ID" "$ADMIN_GROUP_ID")

      CLIENT_ID=$(echo "$OUTPUT" | jq -r '.id')
      CLIENT_SECRET=$(echo "$OUTPUT" | jq -r '.secret')

      kubectl exec vault-0 -n ${var.secrets_ns} -- vault login ${local.vault_token}
      kubectl exec vault-0 -n ${var.secrets_ns} -- vault kv put -mount=kv tools/argo oidc.positron.clientID="$CLIENT_ID" oidc.positron.clientSecret="$CLIENT_SECRET" webhook.github.secret="${var.github_webhook}"
    EOT
  }

  depends_on = [null_resource.wait_for_positron]
}

resource "null_resource" "hibernation_secrets" {
  provisioner "local-exec" {
    command = <<-EOT
      set -euo pipefail

      GROUP_ID=$(${local.positron_exec} group create Hibernation)
      ADMIN_GROUP_ID=$(${local.positron_exec} group create "Hibernation Admin")
      OUTPUT=$(${local.positron_exec} oauth-client create Hibernation https://cache.profidev.io/api/auth/oidc/callback openid,profile,email,image "$GROUP_ID" "$ADMIN_GROUP_ID")

      CLIENT_ID=$(echo "$OUTPUT" | jq -r '.id')
      CLIENT_SECRET=$(echo "$OUTPUT" | jq -r '.secret')

      kubectl exec vault-0 -n ${var.secrets_ns} -- vault login ${local.vault_token}
      kubectl exec vault-0 -n ${var.secrets_ns} -- vault kv patch -mount=kv db/hibernation ${local.oidc_base_config} OIDC_CLIENT_ID="$CLIENT_ID" OIDC_CLIENT_SECRET="$CLIENT_SECRET"
    EOT
  }

  depends_on = [null_resource.wait_for_positron]
}

resource "null_resource" "ichwilldich_sep_secrets" {
  provisioner "local-exec" {
    command = <<-EOT
      set -euo pipefail

      GROUP_ID=$(${local.positron_exec} group create "Ichwilldich SEP")
      ADMIN_GROUP_ID=$(${local.positron_exec} group create "Ichwilldich SEP Admin")
      OUTPUT=$(${local.positron_exec} oauth-client create "Ichwilldich SEP" https://sap.profidev.io/api/auth/oidc/callback openid,profile,email,image "$GROUP_ID" "$ADMIN_GROUP_ID")

      CLIENT_ID=$(echo "$OUTPUT" | jq -r '.id')
      CLIENT_SECRET=$(echo "$OUTPUT" | jq -r '.secret')

      kubectl exec vault-0 -n ${var.secrets_ns} -- vault login ${local.vault_token}
      kubectl exec vault-0 -n ${var.secrets_ns} -- vault kv patch -mount=kv apps/ichwilldich-sep ${local.oidc_base_config} OIDC_CLIENT_ID="$CLIENT_ID" OIDC_CLIENT_SECRET="$CLIENT_SECRET"
    EOT
  }

  depends_on = [null_resource.wait_for_positron]
}
