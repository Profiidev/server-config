resource "kubernetes_namespace" "pg" {
  metadata {
    name = var.pg_ns
  }
}

resource "helm_release" "postgres" {
  name       = "postgres"
  repository = "oci://registry-1.docker.io/bitnamicharts"
  chart      = "postgresql"
  version    = "18.1.11"
  namespace  = var.pg_ns

  values = [templatefile("${path.module}/templates/postgres.values.tftpl", {
  })]

  depends_on = [kubernetes_namespace.pg]
}

resource "kubectl_manifest" "postgres_secrets" {
  yaml_body = <<YAML
apiVersion: external-secrets.io/v1
kind: ExternalSecret
metadata:
  name: postgres
  namespace: ${var.pg_ns}
spec:
  refreshInterval: 5m
  secretStoreRef:
    name: ${var.cluster_secret_store}
    kind: ClusterSecretStore
  target:
    name: postgres-credentials
  dataFrom:
  - extract:
      key: db/postgres
  YAML

  depends_on = [kubernetes_namespace.pg]
}
