resource "kubernetes_namespace" "rustfs" {
  metadata {
    name = var.rustfs_ns
  }
}

resource "helm_release" "minio" {
  name       = "rustfs"
  repository = "https://charts.rustfs.com"
  chart      = "rustfs"
  version    = "0.0.69"
  namespace  = var.rustfs_ns

  values = [templatefile("${path.module}/templates/rustfs.values.tftpl", {
    storage_class = var.storage_class
  })]

  depends_on = [kubernetes_namespace.rustfs]
}
