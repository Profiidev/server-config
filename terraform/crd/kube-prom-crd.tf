resource "kubernetes_namespace" "metrics" {
  metadata {
    name = var.metrics_ns
  }
}

resource "helm_release" "k8s_dashboards" {
  name       = "prometheus"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  version    = "79.0.0"
  namespace  = var.metrics_ns

  values = [templatefile("${path.module}/templates/kube-prom.values.tftpl", {})]

  depends_on = [kubernetes_namespace.metrics]
}

resource "kubectl_manifest" "prometheus_k8s_api_egress" {
  yaml_body = <<YAML
apiVersion: crd.projectcalico.org/v1
kind: NetworkPolicy
metadata:
  name: k8s-api-egress
  namespace: ${var.metrics_ns}
spec:
  order: 10
  types:
    - Egress
  egress:
    - action: Allow
      protocol: TCP
      destination:
        nets:
          - ${var.k8s_api}/32
        ports:
          - 6443
          - 9100
          - 10249
          - 10250
          - 10254
          - 10257
          - 10259
          - 2381
  YAML

  depends_on = [kubernetes_namespace.metrics]
}

module "ns_np_metrics" {
  source = "../modules/ns-np"

  namespace = var.metrics_ns

  depends_on = [kubernetes_namespace.metrics]
}
