resource "kubernetes_namespace" "metrics" {
  metadata {
    name = var.metrics_ns
  }
}

resource "helm_release" "k8s_dashboards" {
  name       = "prometheus"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  version    = "85.0.2"
  namespace  = kubernetes_namespace.metrics.metadata[0].name

  values = [templatefile("${path.module}/templates/kube-prom.values.tftpl", {})]
}
