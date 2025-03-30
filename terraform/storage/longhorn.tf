resource "kubernetes_namespace" "storage_ns" {
  metadata {
    name = var.storage_ns
  }
}

resource "helm_release" "longhorn" {
  name       = "longhorn"
  repository = "https://charts.longhorn.io"
  chart      = "longhorn"
  version    = "1.8.1"
  namespace  = var.storage_ns

  values = [templatefile("${path.module}/templates/longhorn.values.tftpl", {
    #! Affinity
    count = 1
  })]

  depends_on = [kubernetes_namespace.storage_ns]
}
