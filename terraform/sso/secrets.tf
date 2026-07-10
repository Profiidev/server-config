locals {
  positron_exec = "kubectl exec -n ${var.positron_ns} deploy/positron -- positron"

  oidc_config_map = {
    SKIP_SETUP           = "true"
    OIDC_ENABLED         = "true"
    OIDC_ISSUER          = "https://profidev.io/api/oauth"
    OIDC_SCOPES          = "openid email profile image"
    OIDC_GROUP_SYNC      = "true"
    OIDC_IMAGE_SYNC      = "true"
    OIDC_PKCE            = "true"
    SSO_INSTANT_REDIRECT = "true"
    SSO_CREATE_USER      = "true"
  }
}

module "longhorn" {
  source = "../modules/app-oidc"

  secret_path   = "tools/longhorn-proxy"
  cookie_secret = true

  oidc = {
    client_name  = "Longhorn"
    redirect_uri = "https://longhorn.profidev.io/oidc/callback"
    scope        = "openid,profile,email"
  }

  depends_on = [null_resource.wait_for_positron]
}

module "crowdsec" {
  source = "../modules/app-oidc"

  secret_path   = "tools/crowdsec-proxy"
  cookie_secret = true

  oidc = {
    client_name  = "Crowdsec"
    redirect_uri = "https://crowdsec.profidev.io/oidc/callback"
    scope        = "openid,profile,email"
  }

  depends_on = [null_resource.wait_for_positron]
}

module "alloy" {
  source = "../modules/app-oidc"

  secret_path   = "apps/alloy-proxy"
  cookie_secret = true

  oidc = {
    client_name  = "Alloy"
    redirect_uri = "https://alloy.profidev.io/oidc/callback"
    scope        = "openid,profile,email"
  }

  depends_on = [null_resource.wait_for_positron]
}

module "treafik" {
  source = "../modules/app-oidc"

  secret_path   = "tools/traefik-proxy"
  cookie_secret = true

  oidc = {
    client_name  = "Traefik"
    redirect_uri = "https://traefik.profidev.io/oidc/callback"
    scope        = "openid,profile,email"
  }

  depends_on = [null_resource.wait_for_positron]
}

module "radar" {
  source = "../modules/app-oidc"

  secret_path   = "tools/radar"
  cookie_secret = true

  oidc = {
    client_name  = "Radar"
    redirect_uri = "https://radar.profidev.io/oidc/callback"
    scope        = "openid,profile,email"
  }

  depends_on = [null_resource.wait_for_positron]
}

resource "null_resource" "forgejo_ssh" {
  provisioner "local-exec" {
    command = <<-EOT
      set -euo pipefail

      cd ${path.module}
      mkdir -p ../storage/certs/forgejo
      if [ ! -f ../storage/certs/forgejo/ssh_key ]; then
        ssh-keygen -t ed25519 -f ../storage/certs/forgejo/ssh_key -N ""
      fi
    EOT
  }
}

data "local_file" "forgejo_ssh_key" {
  filename   = "${path.module}/../storage/certs/forgejo/ssh_key"
  depends_on = [null_resource.forgejo_ssh]
}

module "forgejo" {
  source = "../modules/app-oidc"

  secret_path = "tools/forgejo"
  create      = false

  oidc = {
    client_name  = "Forgejo"
    redirect_uri = "https://git.profidev.io/user/oauth2/Positron/callback"
    scope        = "openid,profile,email,image"
  }

  client_id_var     = "key"
  client_secret_var = "secret"

  additional_secrets = {
    privateKey = data.local_file.forgejo_ssh_key.content
  }

  depends_on = [null_resource.wait_for_positron]
}

module "argocd" {
  source = "../modules/app-oidc"

  secret_path = "tools/argo"

  oidc = {
    client_name  = "ArgoCD"
    redirect_uri = "https://argocd.profidev.io/auth/callback"
    scope        = "openid,profile,email"
    admin_group  = "ArgoCD Admin"
  }

  client_id_var     = "oidc.positron.clientID"
  client_secret_var = "oidc.positron.clientSecret"

  additional_secrets = {
    "webhook.github.secret" = var.github_webhook
  }

  depends_on = [null_resource.wait_for_positron]
}

module "hibernation" {
  source = "../modules/app-oidc"

  secret_path = "db/hibernation"
  create      = false

  oidc = {
    client_name  = "Hibernation"
    redirect_uri = "https://cache.profidev.io/api/auth/oidc/callback"
    scope        = "openid,profile,email,image"
    admin_group  = "Hibernation Admin"
  }

  require_pkce      = true
  client_id_var     = "OIDC_CLIENT_ID"
  client_secret_var = "OIDC_CLIENT_SECRET"

  additional_secrets = merge(local.oidc_config_map, {
    ADMIN_GROUP = "Hibernation Admin"
  })

  depends_on = [null_resource.wait_for_positron]
}

module "grafana" {
  source = "../modules/app-oidc"

  secret_path = "apps/grafana-oidc"
  create      = false

  oidc = {
    client_name  = "Grafana"
    redirect_uri = "https://grafana.profidev.io/login/generic_oauth"
    scope        = "openid,profile,email,grafana"
    admin_group  = "Grafana Admin"
  }

  client_id_var     = "GF_AUTH_GENERIC_OAUTH_CLIENT_ID"
  client_secret_var = "GF_AUTH_GENERIC_OAUTH_CLIENT_SECRET"

  extra_oidc_create = <<-EOT
    POLICY_ID=$(${local.positron_exec} oauth-policy create Grafana role Viewer $ADMIN_GROUP_ID:Admin)
    ${local.positron_exec} oauth-scope create Grafana grafana $POLICY_ID
  EOT

  extra_oidc_destroy = <<-EOT
    ${local.positron_exec} oauth-scope delete Grafana
    ${local.positron_exec} oauth-policy delete Grafana
  EOT

  depends_on = [null_resource.wait_for_positron]
}
