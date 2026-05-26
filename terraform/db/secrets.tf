locals {
  smpt_config = "SMTP_SERVER=\"smtp.protonmail.ch\" SMTP_PORT=\"587\" SMTP_USERNAME=\"${var.smtp_username}\" SMTP_PASSWORD=\"${var.smtp_password}\" SMTP_FROM_ADDRESS=\"${var.smtp_username}\" SMTP_ENABLED=\"true\" SMTP_USE_TLS=\"false\""
}

resource "null_resource" "positron_bucket_and_secret" {
  provisioner "local-exec" {
    command = <<-EOT
      set -euo pipefail

      EXEC="kubectl exec -n ${kubernetes_namespace.garage.metadata[0].name} garage-0 -c garage -- /garage"
      SET_SECRET="kubectl exec vault-0 -n ${var.secrets_ns} -- vault kv patch -mount=kv apps/positron"

      kubectl exec vault-0 -n ${var.secrets_ns} -- vault login ${local.vault_token}
      kubectl exec vault-0 -n ${var.secrets_ns} -- vault kv put -mount=kv apps/positron S3_HOST="http://garage.${kubernetes_namespace.garage.metadata[0].name}.svc.cluster.local:3900"

      # tempo
      OUTPUT=$($EXEC key create positron)
      KEY_ID=$(echo "$OUTPUT" | grep -oP 'Key ID:\s+\K\S+')
      SECRET=$(echo "$OUTPUT" | grep -oP 'Secret key:\s+\K\S+')
      $SET_SECRET S3_ACCESS_KEY="$KEY_ID" S3_SECRET_KEY="$SECRET" S3_REGION="garage" S3_FORCE_PATH_STYLE="true" S3_BUCKET="positron" SITE_URL="https://profidev.io" DB_URL="${local.db_url_positron}" ${local.smpt_config} SMTP_FROM_NAME="Positron" APOD_API_KEY="${var.apod_api_key}"

      $EXEC bucket create positron
      $EXEC bucket allow positron --key "$KEY_ID" --read --write
    EOT
  }

  depends_on = [helm_release.garage, null_resource.garage_init, null_resource.garage_metrics_buckets]
}

resource "null_resource" "hibernation_bucket_and_secret" {
  provisioner "local-exec" {
    command = <<-EOT
      set -euo pipefail

      EXEC="kubectl exec -n ${kubernetes_namespace.garage.metadata[0].name} garage-0 -c garage -- /garage"
      SET_SECRET="kubectl exec vault-0 -n ${var.secrets_ns} -- vault kv patch -mount=kv db/hibernation"

      kubectl exec vault-0 -n ${var.secrets_ns} -- vault login ${local.vault_token}
      kubectl exec vault-0 -n ${var.secrets_ns} -- vault kv put -mount=kv db/hibernation S3_HOST="http://garage.${kubernetes_namespace.garage.metadata[0].name}.svc.cluster.local:3900"

      # tempo
      OUTPUT=$($EXEC key create hibernation)
      KEY_ID=$(echo "$OUTPUT" | grep -oP 'Key ID:\s+\K\S+')
      SECRET=$(echo "$OUTPUT" | grep -oP 'Secret key:\s+\K\S+')
      $SET_SECRET S3_ACCESS_KEY="$KEY_ID" S3_SECRET_KEY="$SECRET" S3_REGION="garage" S3_FORCE_PATH_STYLE="true" S3_BUCKET="hibernation" SITE_URL="https://cache.profidev.io" VIRTUAL_HOST_ROUTING="true" DB_URL="${local.db_url_hibernation}" ${local.smpt_config} SMTP_FROM_NAME="Hibernation"

      $EXEC bucket create hibernation
      $EXEC bucket allow hibernation --key "$KEY_ID" --read --write
    EOT
  }

  depends_on = [helm_release.garage, null_resource.garage_init, null_resource.garage_metrics_buckets]
}
