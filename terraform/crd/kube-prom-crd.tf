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

resource "kubernetes_service" "kubelet_metrics" {
  metadata {
    name      = "prometheus-kube-prometheus-kubelet"
    namespace = "kube-system"

    labels = {
      "app.kubernetes.io/name"    = "kubelet"
      "k8s-app"                   = "kubelet"
    }
  }

  spec {
    port {
      name        = "https-metrics"
      port        = 10250
      target_port = 10250
      protocol    = "TCP"
    }

    type = "ClusterIP"
  }
}

data "kubernetes_nodes" "all" {}

resource "kubernetes_endpoints" "kubelet_metrics" {
  metadata {
    name      = "prometheus-kube-prometheus-kubelet"
    namespace = "kube-system"
    labels = {
      "k8s-app" = "kubelet"
    }
  }

  subset {
    dynamic "address" {
      for_each = data.kubernetes_nodes.all.nodes
      content {
        # Selects the InternalIP of each node
        ip = [for addr in address.value.status[0].addresses : addr.address if addr.type == "InternalIP"][0]
      }
    }

    port {
      name     = "https-metrics"
      port     = 10250
      protocol = "TCP"
    }
  }
}
