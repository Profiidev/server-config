resource "kubernetes_namespace" "storage" {
  metadata {
    name = var.storage_ns
  }
}

resource "helm_release" "longhorn" {
  name       = "longhorn"
  repository = "https://charts.longhorn.io"
  chart      = "longhorn"
  version    = "1.10.0"
  namespace  = kubernetes_namespace.storage.metadata[0].name

  values = [templatefile("${path.module}/templates/longhorn.values.tftpl", {
    #! Affinity
    count = 3,
  })]
}

resource "kubectl_manifest" "longhorn_secret" {
  yaml_body = <<YAML
apiVersion: external-secrets.io/v1
kind: ExternalSecret
metadata:
  name: longhorn-secret
  namespace: ${kubernetes_namespace.storage.metadata[0].name}
spec:
  refreshInterval: 5m
  secretStoreRef:
    name: ${var.cluster_secret_store}
    kind: ClusterSecretStore
  target:
    name: longhorn-secret
  dataFrom:
  - extract:
      key: tools/longhorn
  YAML

  depends_on = [helm_release.longhorn]
}

resource "kubectl_manifest" "longhorn_db_backup" {
  yaml_body = <<YAML
apiVersion: longhorn.io/v1beta2
kind: RecurringJob
metadata:
  name: longhorn-db-backup
  namespace: ${kubernetes_namespace.storage.metadata[0].name}
spec:
  cron: "0 0 * * *"
  task: backup-force-create
  retain: 3
  concurrency: 1
YAML

  depends_on = [helm_release.longhorn]
}

resource "kubectl_manifest" "longhorn_fs_trim" {
  yaml_body = <<YAML
apiVersion: longhorn.io/v1beta2
kind: RecurringJob
metadata:
  name: longhorn-fs-trim
  namespace: ${kubernetes_namespace.storage.metadata[0].name}
spec:
  cron: "0 0 * * *"
  task: filesystem-trim
  retain: 0
  concurrency: 1
  groups:
  - default
YAML

  depends_on = [helm_release.longhorn]
}
