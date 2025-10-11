resource "kubernetes_namespace" "couchdb_ns" {
  metadata {
    name = var.couchdb_ns
    labels = {
      "${var.cloudflare_cert_label.key}" = var.cloudflare_cert_label.value
      "${var.secret_store_label.key}"    = var.secret_store_label.value
      "${var.cluster_ca_cert_label.key}" = var.cluster_ca_cert_label.value
    }
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
    uuid = random_uuid.couchdb_uuid.result
  })]

  depends_on = [kubernetes_namespace.couchdb_ns]
}

resource "kubectl_manifest" "couchdb_secrets" {
  yaml_body = <<YAML
apiVersion: external-secrets.io/v1beta1
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
      key: apps/couchdb
  YAML

  depends_on = [kubernetes_namespace.couchdb_ns]
}
