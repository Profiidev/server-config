resource "kubernetes_namespace" "garage" {
  metadata {
    name = var.garage_ns
  }
}

resource "random_password" "garage_token" {
  length  = 16
  special = true
}

resource "helm_release" "garage" {
  name       = "garage"
  repository = "https://profiidev.github.io/helm-charts"
  chart      = "garage"
  version    = "0.9.4"
  namespace  = kubernetes_namespace.garage.metadata[0].name

  values = [templatefile("${path.module}/templates/garage.values.tftpl", {
    token = random_password.garage_token.result
  })]
}

resource "null_resource" "garage_init" {
  provisioner "local-exec" {
    command = <<-EOT
      EXEC="kubectl exec -n ${kubernetes_namespace.garage.metadata[0].name} garage-0 -c garage -- /garage"
      NODE_ID=$($EXEC node id -q)
      $EXEC layout assign $NODE_ID -z default -c 107GB
      $EXEC layout show
      $EXEC layout apply --version 1
    EOT
  }

  depends_on = [helm_release.garage]
}

locals {
  vault_token = jsondecode(file("${path.module}/../storage/certs/global_token.json")).token
}

resource "null_resource" "garage_metrics_buckets" {
  provisioner "local-exec" {
    command = <<-EOT
      set -euo pipefail

      EXEC="kubectl exec -n ${kubernetes_namespace.garage.metadata[0].name} garage-0 -c garage -- /garage"
      SET_SECRET="kubectl exec vault-0 -n ${var.secrets_ns} -- vault kv patch -mount=kv apps/lgtm"

      kubectl exec vault-0 -n ${var.secrets_ns} -- vault login ${local.vault_token}
      kubectl exec vault-0 -n ${var.secrets_ns} -- vault kv put -mount=kv apps/lgtm GRAFANA_S3_ENDPOINT="garage.${kubernetes_namespace.garage.metadata[0].name}.svc.cluster.local:3900"

      # loki
      OUTPUT=$($EXEC key create loki)
      KEY_ID=$(echo "$OUTPUT" | grep -oP 'Key ID:\s+\K\S+')
      SECRET=$(echo "$OUTPUT" | grep -oP 'Secret key:\s+\K\S+')
      $SET_SECRET GRAFANA_LOKI_S3_ACCESS_KEY="$KEY_ID" GRAFANA_LOKI_S3_SECRET_KEY="$SECRET"

      $EXEC bucket create loki-admin
      $EXEC bucket create loki-chunk
      $EXEC bucket create loki-ruler

      $EXEC bucket allow loki-admin --key "$KEY_ID" --read --write
      $EXEC bucket allow loki-chunk --key "$KEY_ID" --read --write
      $EXEC bucket allow loki-ruler --key "$KEY_ID" --read --write

      # mimir
      OUTPUT=$($EXEC key create mimir)
      KEY_ID=$(echo "$OUTPUT" | grep -oP 'Key ID:\s+\K\S+')
      SECRET=$(echo "$OUTPUT" | grep -oP 'Secret key:\s+\K\S+')
      $SET_SECRET GRAFANA_MIMIR_S3_ACCESS_KEY="$KEY_ID" GRAFANA_MIMIR_S3_SECRET_KEY="$SECRET"

      $EXEC bucket create mimir-alert
      $EXEC bucket create mimir-blocks
      $EXEC bucket create mimir-ruler

      $EXEC bucket allow mimir-alert --key "$KEY_ID" --read --write
      $EXEC bucket allow mimir-blocks --key "$KEY_ID" --read --write
      $EXEC bucket allow mimir-ruler --key "$KEY_ID" --read --write

      # tempo
      OUTPUT=$($EXEC key create tempo)
      KEY_ID=$(echo "$OUTPUT" | grep -oP 'Key ID:\s+\K\S+')
      SECRET=$(echo "$OUTPUT" | grep -oP 'Secret key:\s+\K\S+')
      $SET_SECRET GRAFANA_TEMPO_S3_ACCESS_KEY="$KEY_ID" GRAFANA_TEMPO_S3_SECRET_KEY="$SECRET"

      $EXEC bucket create tempo
      $EXEC bucket allow tempo --key "$KEY_ID" --read --write
    EOT
  }

  depends_on = [helm_release.garage, null_resource.garage_init]
}

resource "null_resource" "garage_longhorn_buckets" {
  provisioner "local-exec" {
    command = <<-EOT
      set -euo pipefail

      EXEC="kubectl exec -n ${kubernetes_namespace.garage.metadata[0].name} garage-0 -c garage -- /garage"
      SET_SECRET="kubectl exec vault-0 -n ${var.secrets_ns} -- vault kv patch -mount=kv tools/longhorn"

      kubectl exec vault-0 -n ${var.secrets_ns} -- vault login ${local.vault_token}
      kubectl exec vault-0 -n ${var.secrets_ns} -- vault kv put -mount=kv tools/longhorn AWS_ENDPOINTS="http://garage.${kubernetes_namespace.garage.metadata[0].name}.svc.cluster.local:3900"

      # tempo
      OUTPUT=$($EXEC key create longhorn)
      KEY_ID=$(echo "$OUTPUT" | grep -oP 'Key ID:\s+\K\S+')
      SECRET=$(echo "$OUTPUT" | grep -oP 'Secret key:\s+\K\S+')
      $SET_SECRET AWS_ACCESS_KEY_ID="$KEY_ID" AWS_SECRET_ACCESS_KEY="$SECRET"

      $EXEC bucket create longhorn
      $EXEC bucket allow longhorn --key "$KEY_ID" --read --write
    EOT
  }

  depends_on = [helm_release.garage, null_resource.garage_init, null_resource.garage_metrics_buckets]
}
