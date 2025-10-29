resource "kubernetes_namespace" "couchdb" {
  metadata {
    name = var.couchdb_ns
  }
}

resource "random_uuid" "couchdb_uuid" {}

resource "helm_release" "couchdb" {
  name       = "couchdb"
  repository = "https://apache.github.io/couchdb-helm/"
  chart      = "couchdb"
  version    = "4.6.2"
  namespace  = var.couchdb_ns

  values = [templatefile("${path.module}/templates/couchdb.values.tftpl", {
    uuid        = random_uuid.couchdb_uuid.result
    cert_issuer = var.cert_issuer_prod
  })]

  depends_on = [kubernetes_namespace.couchdb]
}

resource "kubectl_manifest" "couchdb_secrets" {
  yaml_body = <<YAML
apiVersion: external-secrets.io/v1
kind: ExternalSecret
metadata:
  name: couchdb
  namespace: ${var.couchdb_ns}
spec:
  refreshInterval: 15s
  secretStoreRef:
    name: ${var.cluster_secret_store}
    kind: ClusterSecretStore
  target:
    name: couchdb
  dataFrom:
  - extract:
      key: db/couchdb
  YAML

  depends_on = [kubernetes_namespace.couchdb]
}
