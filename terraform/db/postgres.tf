resource "kubernetes_namespace" "pg" {
  metadata {
    name = var.pg_ns
  }
}

resource "random_password" "postgres_password" {
  length  = 16
  special = true
}

resource "helm_release" "postgres" {
  name       = "postgres"
  repository = "oci://registry-1.docker.io/bitnamicharts"
  chart      = "postgresql"
  version    = "18.7.13"
  namespace  = var.pg_ns

  values = [templatefile("${path.module}/templates/postgres.values.tftpl", {
    password = random_password.postgres_password.result
  })]

  depends_on = [kubernetes_namespace.pg]
}
