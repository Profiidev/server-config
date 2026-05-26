resource "kubernetes_namespace" "pg" {
  metadata {
    name = var.pg_ns
  }
}

resource "random_password" "postgres_password" {
  length  = 16
  special = true
}

locals {
  db_url_base = "postgres://postgres:${random_password.postgres_password.result}@postgres-postgresql.${kubernetes_namespace.pg.metadata[0].name}.svc:5432"
  db_url_positron = "${local.db_url_base}/positron?sslmode=disable"
  db_url_hibernation = "${local.db_url_base}/hibernation?sslmode=disable"
  db_url_auto_clean_bot = "${local.db_url_base}/auto_clean_bot?sslmode=disable"
  db_url_ichwilldich_sep = "${local.db_url_base}/ichwilldich_sep?sslmode=disable"
}

resource "helm_release" "postgres" {
  name       = "postgres"
  repository = "oci://registry-1.docker.io/bitnamicharts"
  chart      = "postgresql"
  version    = "18.6.5"
  namespace  = var.pg_ns

  values = [templatefile("${path.module}/templates/postgres.values.tftpl", {
    password = random_password.postgres_password.result
  })]

  depends_on = [kubernetes_namespace.pg]
}

resource "null_resource" "create_db" {
  provisioner "local-exec" {
    command = <<-EOT
      set -euo pipefail

      EXEC="kubectl exec -n ${var.pg_ns} postgres-postgresql-0 -c postgresql -- env PGPASSWORD=${random_password.postgres_password.result} psql -U postgres"
      $EXEC -c "CREATE DATABASE positron;"
      $EXEC -c "CREATE DATABASE hibernation;"
      $EXEC -c "CREATE DATABASE auto_clean_bot;"
      $EXEC -c "CREATE DATABASE ichwilldich_sep;"
    EOT
  }

  depends_on = [helm_release.postgres]
}
