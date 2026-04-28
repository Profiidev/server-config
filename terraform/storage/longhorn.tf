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
  namespace  = var.storage_ns

  values = [templatefile("${path.module}/templates/longhorn.values.tftpl", {
    #! Affinity
    count = 1,
  })]

  depends_on = [kubernetes_namespace.storage]
}

module "k8s_api_np_longhorn" {
  source = "../modules/k8s-api-np"

  namespace = var.storage_ns
  k8s_api   = var.k8s_api

  depends_on = [kubernetes_namespace.storage]
}

resource "kubectl_manifest" "longhorn_secret" {
  yaml_body = <<YAML
apiVersion: external-secrets.io/v1
kind: ExternalSecret
metadata:
  name: longhorn-secret
  namespace: ${var.storage_ns}
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

  depends_on = [kubernetes_namespace.storage]
}

resource "kubectl_manifest" "longhorn_db_backup" {
  yaml_body = <<YAML
apiVersion: longhorn.io/v1beta2
kind: RecurringJob
metadata:
  name: longhorn-db-backup
  namespace: ${var.storage_ns}
spec:
  cron: "0 0 * * *"
  task: backup-force-create
  retain: 3
  concurrency: 1
YAML

  depends_on = [kubernetes_namespace.storage]
}

resource "kubectl_manifest" "longhorn_fs_trim" {
  yaml_body = <<YAML
apiVersion: longhorn.io/v1beta2
kind: RecurringJob
metadata:
  name: longhorn-fs-trim
  namespace: ${var.storage_ns}
spec:
  cron: "0 0 * * *"
  task: filesystem-trim
  retain: 0
  concurrency: 1
  groups:
  - default
YAML
}
