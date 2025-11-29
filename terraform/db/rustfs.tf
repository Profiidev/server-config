resource "kubernetes_namespace" "rustfs" {
  metadata {
    name = var.rustfs_ns
  }
}

resource "helm_release" "minio" {
  name       = "rustfs"
  repository = "https://charts.rustfs.com"
  chart      = "rustfs"
  version    = "0.0.70"
  namespace  = var.rustfs_ns

  values = [templatefile("${path.module}/templates/rustfs.values.tftpl", {
    storage_class = var.storage_class
    ingress_class = var.ingress_class
    cert_issuer   = var.cert_issuer_prod
    password      = var.rustfs_password
  })]

  depends_on = [kubernetes_namespace.rustfs]
}
