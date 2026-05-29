locals {
  smtp_config_map = {
    SMTP_SERVER = "smtp.protonmail.ch"
    SMTP_PORT = "587"
    SMTP_USERNAME = var.smtp_username
    SMTP_PASSWORD = var.smtp_password
    SMTP_FROM_ADDRESS = var.smtp_username
    SMTP_ENABLED = "true"
    SMTP_USE_TLS = "false"
  }
}

module "positron" {
  source = "../modules/app-resources"

  secret_path = "apps/positron"

  s3_bucket = "positron"

  db_name = "positron"
  db_password = random_password.postgres_password.result

  additional_secrets = merge(local.smtp_config_map, {
    SITE_URL = "https://profidev.io"
    APOD_API_KEY = var.apod_api_key
    SMTP_FROM_NAME = "Positron"
  })

  depends_on = [null_resource.garage_init, helm_release.postgres]
}

module "hibernation" {
  source = "../modules/app-resources"

  secret_path = "db/hibernation"

  s3_bucket = "hibernation"

  db_name = "hibernation"
  db_password = random_password.postgres_password.result

  additional_secrets = merge(local.smtp_config_map, {
    SITE_URL = "https://cache.profidev.io"
    SMTP_FROM_NAME = "Hibernation"
    VIRTUAL_HOST_ROUTING = "true"
  })

  depends_on = [null_resource.garage_init, helm_release.postgres]
}

module "auto_clean_bot" {
  source = "../modules/app-resources"

  secret_path = "apps/auto-clean-bot"

  db_name = "auto_clean_bot"
  db_password = random_password.postgres_password.result

  additional_secrets = {
    RUST_LOG = "info"
    DISCORD_TOKEN = var.discord_token
  }

  depends_on = [helm_release.postgres]
}

module "ichwildich_sep" {
  source = "../modules/app-resources"

  secret_path = "apps/ichwilldich-sep"

  db_name = "ichwilldich_sep"
  db_password = random_password.postgres_password.result

  additional_secrets = merge(local.smtp_config_map, {
    SITE_URL = "https://sap.profidev.io"
    SMTP_FROM_NAME = "IchWillDich SEP"
  })

  depends_on = [helm_release.postgres]
}

module "alert_bot" {
  source = "../modules/app-resources"

  secret_path = "apps/alert-bot"

  additional_secrets = {
    proxy = "http://alert-bot-alertmanager-discord.metrics.svc:9094"
    url = var.discord_alert_webhook
  }
}

module "grafana_dummy" {
  source = "../modules/app-resources"

  secret_path = "apps/grafana-oidc"

  additional_secrets = {
    GF_AUTH_GENERIC_OAUTH_CLIENT_ID = ""
    GF_AUTH_GENERIC_OAUTH_CLIENT_SECRET = ""
  }
}

module "forgejo" {
  source = "../modules/app-resources"

  secret_path = "tools/forgejo"

  s3_bucket = "forgejo"
  s3_access_key_var = "FORGEJO__storage__MINIO_ACCESS_KEY_ID"
  s3_secret_key_var = "FORGEJO__storage__MINIO_SECRET_ACCESS_KEY"

  db_name = "forgejo"
  db_password = random_password.postgres_password.result

  additional_secrets = {
    FORGEJO__database__HOST = "postgres-postgresql.${var.pg_ns}.svc:5432"
    FORGEJO__database__USER = "postgres"
    FORGEJO__database__PASSWD = random_password.postgres_password.result
    FORGEJO__storage__MINIO_ENDPOINT = "garage.${var.garage_ns}.svc.cluster.local:3900"
  }

  depends_on = [null_resource.garage_init, helm_release.postgres]
}
