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
