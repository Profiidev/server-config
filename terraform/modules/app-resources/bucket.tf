resource "random_integer" "destory_port" {
  min = 10000
  max = 60000
}

resource "terraform_data" "app_bucket" {
  count = var.s3_bucket != null && var.enabled ? 1 : 0

  input = {
    secrets_ns     = var.secrets_ns
    secret_path    = var.secret_path
    s3_ns          = var.s3_ns
    vault_exec     = local.vault_exec
    vault_token    = local.vault_token
    exec           = local.s3_exec
    bucket         = var.s3_bucket
    key_var        = var.s3_access_key_var
    secret_var     = var.s3_secret_key_var
    region_var     = var.s3_region_var
    bucket_var     = var.s3_bucket_var
    host_var       = var.s3_host_var
    host           = local.s3_host
    path_style_var = var.s3_force_path_style_var
    path_style     = var.s3_force_path_style ? "true" : "false"
    destroy_port   = random_integer.destory_port.result
  }

  provisioner "local-exec" {
    command = <<-EOT
      set -euo pipefail

      OUTPUT=$(${self.input.exec} key create ${self.input.bucket})
      KEY_ID=$(echo "$OUTPUT" | grep -oP 'Key ID:\s+\K\S+')
      SECRET=$(echo "$OUTPUT" | grep -oP 'Secret key:\s+\K\S+')

      ${self.input.exec} bucket create ${self.input.bucket}
      ${self.input.exec} bucket allow ${self.input.bucket} --key "$KEY_ID" --read --write

      ${self.input.vault_exec} ${self.input.key_var}="$KEY_ID" ${self.input.secret_var}="$SECRET" ${self.input.region_var}="garage" ${self.input.bucket_var}="${self.input.bucket}" ${self.input.host_var}="${self.input.host}" ${self.input.path_style_var}="${self.input.path_style}"
    EOT
  }

  provisioner "local-exec" {
    when    = destroy
    command = <<-EOT
      set -euo pipefail

      kubectl exec vault-0 -n ${self.input.secrets_ns} -- vault login ${self.input.vault_token}
      SECRET=$(kubectl exec vault-0 -n ${self.input.secrets_ns} -- vault kv get -mount=kv -format=json ${self.input.secret_path})

      export AWS_ACCESS_KEY_ID=$(echo "$SECRET" | jq -r '.data.data["${self.input.key_var}"]')
      export AWS_SECRET_ACCESS_KEY=$(echo "$SECRET" | jq -r '.data.data["${self.input.secret_var}"]')

      kubectl port-forward -n ${self.input.s3_ns} svc/garage ${self.input.destroy_port}:3900 &
      PORT_FORWARD_PID=$!
      sleep 5

      aws s3 rm s3://${self.input.bucket} --recursive --endpoint-url http://localhost:${self.input.destroy_port} --region garage

      kill $PORT_FORWARD_PID

      ${self.input.exec} bucket delete ${self.input.bucket} --yes
      ${self.input.exec} key delete ${self.input.bucket} --yes
    EOT
  }

  depends_on = [terraform_data.app_secret]
}
