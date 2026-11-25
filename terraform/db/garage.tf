resource "kubernetes_namespace" "garage" {
  metadata {
    name = var.garage_ns
  }
}

resource "random_password" "garage_token" {
  length  = 32
  special = false
}

resource "helm_release" "garage" {
  name       = "garage"
  repository = "https://profiidev.github.io/helm-charts"
  chart      = "garage"
  version    = "0.9.5"
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

resource "helm_release" "garage_webui" {
  name       = "garage-webui"
  repository = "https://helm.noste.dev"
  chart      = "garage-ui"
  version    = "0.14.0"
  namespace  = kubernetes_namespace.garage.metadata[0].name

  values = [templatefile("${path.module}/templates/garage-webui.values.tftpl", {
    namespace       = kubernetes_namespace.garage.metadata[0].name
    ingress_class   = var.ingress_class
    cloudflare_cert = var.cloudflare_cert_var
  })]

  set_sensitive = [{
    name  = "config.garage.admin_token"
    value = random_password.garage_token.result
  }]

  depends_on = [null_resource.garage_init]
}

resource "kubectl_manifest" "garage_proxy_secrets" {
  yaml_body = <<YAML
apiVersion: external-secrets.io/v1
kind: ExternalSecret
metadata:
  name: garage-proxy
  namespace: ${var.garage_ns}
spec:
  refreshInterval: 5m
  secretStoreRef:
    name: ${var.cluster_secret_store}
    kind: ClusterSecretStore
  target:
    name: garage-proxy
  dataFrom:
  - extract:
      key: tools/garage-proxy
  YAML

  depends_on = [kubernetes_namespace.garage]
}

resource "kubectl_manifest" "garage_oidc_middleware" {
  yaml_body = <<YAML
apiVersion: traefik.io/v1alpha1
kind: Middleware
metadata:
  name: garage
  namespace: ${var.garage_ns}
spec:
  plugin:
    traefik-oidc-auth:
      Secret: "urn:k8s:secret:garage-proxy:secret"
      Provider:
        ClientId: "urn:k8s:secret:garage-proxy:client-id"
        ClientSecret: "urn:k8s:secret:garage-proxy:client-secret"
        Url: "https://profidev.io/api/oauth"
      Scopes:
        - "openid"
        - "profile"
        - "email"
  YAML

  depends_on = [kubernetes_namespace.garage]
}

resource "kubectl_manifest" "garage_tls_options" {
  yaml_body = <<YAML
apiVersion: traefik.io/v1alpha1
kind: TLSOption
metadata:
  name: garage-tls-options
  namespace: ${var.garage_ns}
spec:
  clientAuth:
    clientAuthType: RequireAndVerifyClientCert
    secretNames:
      - ${var.cloudflare_ca_cert_var}
  YAML

  depends_on = [kubernetes_namespace.garage]
}


locals {
  vault_token = jsondecode(file("${path.module}/../storage/certs/global_token.json")).token
}

resource "terraform_data" "garage_metrics_buckets" {
  input = {
    secrets_ns  = var.secrets_ns
    vault_token = local.vault_token
    s3_ns       = var.garage_ns
  }

  provisioner "local-exec" {
    command = <<-EOT
      set -euo pipefail

      EXEC="kubectl exec -n ${self.input.s3_ns} garage-0 -c garage -- /garage"
      SET_SECRET="kubectl exec vault-0 -n ${self.input.secrets_ns} -- vault kv patch -mount=kv apps/lgtm"

      kubectl exec vault-0 -n ${self.input.secrets_ns} -- vault login ${self.input.vault_token}
      kubectl exec vault-0 -n ${self.input.secrets_ns} -- vault kv put -mount=kv apps/lgtm GRAFANA_S3_ENDPOINT="garage.${self.input.s3_ns}.svc.cluster.local:3900"

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

  provisioner "local-exec" {
    when    = destroy
    command = <<-EOT
      set -euo pipefail

      EXEC="kubectl exec -n ${self.input.s3_ns} garage-0 -c garage -- /garage"

      kubectl exec vault-0 -n ${self.input.secrets_ns} -- vault login ${self.input.vault_token}
      SECRET=$(kubectl exec vault-0 -n ${self.input.secrets_ns} -- vault kv get -mount=kv -format=json apps/lgtm)

      kubectl port-forward -n ${self.input.s3_ns} svc/garage 3901:3900 &
      PORT_FORWARD_PID=$!
      sleep 5

      export AWS_ACCESS_KEY_ID=$(echo "$SECRET" | jq -r '.data.data["GRAFANA_TEMPO_S3_ACCESS_KEY"]')
      export AWS_SECRET_ACCESS_KEY=$(echo "$SECRET" | jq -r '.data.data["GRAFANA_TEMPO_S3_SECRET_KEY"]')

      aws s3 rm s3://tempo --recursive --endpoint-url http://localhost:3901 --region garage

      export AWS_ACCESS_KEY_ID=$(echo "$SECRET" | jq -r '.data.data["GRAFANA_LOKI_S3_ACCESS_KEY"]')
      export AWS_SECRET_ACCESS_KEY=$(echo "$SECRET" | jq -r '.data.data["GRAFANA_LOKI_S3_SECRET_KEY"]')

      aws s3 rm s3://loki-admin --recursive --endpoint-url http://localhost:3901 --region garage
      aws s3 rm s3://loki-chunk --recursive --endpoint-url http://localhost:3901 --region garage
      aws s3 rm s3://loki-ruler --recursive --endpoint-url http://localhost:3901 --region garage

      export AWS_ACCESS_KEY_ID=$(echo "$SECRET" | jq -r '.data.data["GRAFANA_MIMIR_S3_ACCESS_KEY"]')
      export AWS_SECRET_ACCESS_KEY=$(echo "$SECRET" | jq -r '.data.data["GRAFANA_MIMIR_S3_SECRET_KEY"]')

      aws s3 rm s3://mimir-alert --recursive --endpoint-url http://localhost:3901 --region garage
      aws s3 rm s3://mimir-blocks --recursive --endpoint-url http://localhost:3901 --region garage
      aws s3 rm s3://mimir-ruler --recursive --endpoint-url http://localhost:3901 --region garage

      kill $PORT_FORWARD_PID

      $EXEC bucket delete tempo --yes
      $EXEC bucket delete loki-admin --yes
      $EXEC bucket delete loki-chunk --yes
      $EXEC bucket delete loki-ruler --yes
      $EXEC bucket delete mimir-alert --yes
      $EXEC bucket delete mimir-blocks --yes
      $EXEC bucket delete mimir-ruler --yes

      $EXEC key delete tempo --yes
      $EXEC key delete loki --yes
      $EXEC key delete mimir --yes

      kubectl exec vault-0 -n ${self.input.secrets_ns} -- vault kv metadata delete -mount=kv apps/lgtm
    EOT
  }

  depends_on = [null_resource.garage_init]
}

resource "terraform_data" "garage_linstor_buckets" {
  input = {
    secrets_ns  = var.secrets_ns
    vault_token = local.vault_token
    s3_ns       = var.garage_ns
    storage_ns  = var.storage_ns
  }

  provisioner "local-exec" {
    command = <<-EOT
      set -euo pipefail

      EXEC="kubectl exec -n ${self.input.s3_ns} garage-0 -c garage -- /garage"
      LINSTOR="kubectl exec -n ${self.input.storage_ns} deploy/linstor-controller -- linstor"
      SET_SECRET="kubectl exec vault-0 -n ${self.input.secrets_ns} -- vault kv patch -mount=kv tools/linstor"

      kubectl exec vault-0 -n ${self.input.secrets_ns} -- vault login ${self.input.vault_token}
      kubectl exec vault-0 -n ${self.input.secrets_ns} -- vault kv put -mount=kv tools/linstor AWS_ENDPOINTS="http://garage.${self.input.s3_ns}.svc.cluster.local:3900"

      OUTPUT=$($EXEC key create linstor)
      KEY_ID=$(echo "$OUTPUT" | grep -oP 'Key ID:\s+\K\S+')
      SECRET=$(echo "$OUTPUT" | grep -oP 'Secret key:\s+\K\S+')
      $SET_SECRET AWS_ACCESS_KEY_ID="$KEY_ID" AWS_SECRET_ACCESS_KEY="$SECRET"

      $EXEC bucket create linstor
      $EXEC bucket allow linstor --key "$KEY_ID" --read --write

      # LINSTOR stores the credentials encrypted with the master passphrase (storage stage)
      $LINSTOR remote create s3 --use-path-style garage http://garage.${self.input.s3_ns}.svc.cluster.local:3900 linstor garage "$KEY_ID" "$SECRET"
      # full daily, incremental every 4h, keep 4 full chains (~4 days)
      $LINSTOR schedule create --incremental-cron "0 4-20/4 * * *" --keep-local 1 --keep-remote 4 \
        --on-failure RETRY --max-retries 3 db-backup "0 0 * * *"
      # storage class linstor-backup uses this resource group; create it so the schedule can be enabled before any PVC
      $LINSTOR resource-group create backup --place-count 3 --storage-pool thin || true
      $LINSTOR backup schedule enable --rg backup garage db-backup
    EOT
  }

  provisioner "local-exec" {
    when    = destroy
    command = <<-EOT
      set -euo pipefail

      EXEC="kubectl exec -n ${self.input.s3_ns} garage-0 -c garage -- /garage"
      LINSTOR="kubectl exec -n ${self.input.storage_ns} deploy/linstor-controller -- linstor"

      $LINSTOR backup schedule disable --rg backup garage db-backup || true
      $LINSTOR schedule delete db-backup || true
      $LINSTOR remote delete garage || true

      kubectl exec vault-0 -n ${self.input.secrets_ns} -- vault login ${self.input.vault_token}
      SECRET=$(kubectl exec vault-0 -n ${self.input.secrets_ns} -- vault kv get -mount=kv -format=json tools/linstor)

      kubectl port-forward -n ${self.input.s3_ns} svc/garage 3902:3900 &
      PORT_FORWARD_PID=$!
      sleep 5

      export AWS_ACCESS_KEY_ID=$(echo "$SECRET" | jq -r '.data.data["AWS_ACCESS_KEY_ID"]')
      export AWS_SECRET_ACCESS_KEY=$(echo "$SECRET" | jq -r '.data.data["AWS_SECRET_ACCESS_KEY"]')

      aws s3 rm s3://linstor --recursive --endpoint-url http://localhost:3902 --region garage

      kill $PORT_FORWARD_PID

      $EXEC bucket delete linstor --yes
      $EXEC key delete linstor --yes

      kubectl exec vault-0 -n ${self.input.secrets_ns} -- vault kv metadata delete -mount=kv tools/linstor
    EOT
  }

  depends_on = [null_resource.garage_init]
}

# LINSTOR bases the next incremental on the last started/queued snapshot, not the last uploaded one. After a
# failed or aborted shipment every later scheduled backup queues on a snapshot that never reached S3 and never
# runs. Drop such snapshots (older than MIN_AGE_HOURS, so running uploads are left alone) before each schedule run;
# the next run then ships a fresh full backup.
resource "kubernetes_cron_job_v1" "linstor_backup_cleanup" {
  metadata {
    name      = "linstor-backup-cleanup"
    namespace = var.storage_ns
  }

  spec {
    # 10 min before every db-backup run (full 00:00, incremental 04:00-20:00 every 4h)
    schedule           = "50 3-23/4 * * *"
    concurrency_policy = "Forbid"

    job_template {
      metadata {}
      spec {
        backoff_limit = 0
        template {
          metadata {}
          spec {
            restart_policy = "Never"
            container {
              name    = "cleanup"
              image   = "quay.io/piraeusdatastore/piraeus-server:v1.35.3"
              command = ["python3", "-c", file("${path.module}/scripts/linstor-backup-cleanup.py")]
              env {
                name  = "LS_CONTROLLERS"
                value = "http://linstor-controller.${var.storage_ns}.svc:3370"
              }
              env {
                name  = "REMOTE"
                value = "garage"
              }
              env {
                name  = "MIN_AGE_HOURS"
                value = "3"
              }
            }
          }
        }
      }
    }
  }

  depends_on = [terraform_data.garage_linstor_buckets]
}
