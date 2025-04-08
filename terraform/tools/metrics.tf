resource "kubernetes_namespace" "metrics_ns" {
  metadata {
    name = var.metrics_ns
    labels = {
      "${var.oidc_access_label.key}"     = var.oidc_access_label.value
      "${var.cloudflare_cert_label.key}" = var.cloudflare_cert_label.value
      "${var.secret_store_label.key}"    = var.secret_store_label.value
    }
  }
}

resource "helm_release" "prometheus" {
  name       = "prometheus"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  version    = "70.4.2"
  namespace  = var.metrics_ns

  values = [templatefile("${path.module}/templates/prometheus.values.tftpl", {
    namespace              = var.metrics_ns
    cloudflare_ca_cert_var = var.cloudflare_ca_cert_var
    cloudflare_cert_var    = var.cloudflare_cert_var
    ingress_class          = var.ingress_class
    storage_class          = var.storage_class
  })]

  depends_on = [kubernetes_namespace.metrics_ns]
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
          - 194.164.200.60/32
        ports:
          - 6443
          - 9100
          - 10250
          - 10254
          - 10257
          - 10259
          - 2381
  YAML

  depends_on = [kubernetes_namespace.metrics_ns]
}

resource "kubectl_manifest" "metrics_ns" {
  yaml_body = <<YAML
apiVersion: crd.projectcalico.org/v1
kind: NetworkPolicy
metadata:
  name: metrics-namespace
  namespace: ${var.metrics_ns}
spec:
  order: 10
  namespaceSelector: kubernetes.io/metadata.name == '${var.metrics_ns}'
  types:
    - Egress
    - Ingress
  egress:
    - action: Allow
      protocol: TCP
      destination:
        namespaceSelector: kubernetes.io/metadata.name == '${var.metrics_ns}'
  ingress:
    - action: Allow
      protocol: TCP
      source:
        namespaceSelector: kubernetes.io/metadata.name == '${var.metrics_ns}'
  YAML

  depends_on = [kubernetes_namespace.metrics_ns]
}

resource "kubectl_manifest" "metrics_oidc" {
  yaml_body = <<YAML
apiVersion: crd.projectcalico.org/v1
kind: NetworkPolicy
metadata:
  name: metrics-oidc
  namespace: ${var.metrics_ns}
spec:
  order: 10
  selector: app.kubernetes.io/name == 'grafana'
  types:
    - Egress
  egress:
    - action: Allow
      protocol: TCP
      destination:
        namespaceSelector: kubernetes.io/metadata.name == '${var.positron_ns}'
        selector: app == 'positron-backend'
        ports:
          - 8000
  YAML

  depends_on = [kubernetes_namespace.portainer_ns]
}

resource "kubectl_manifest" "metrics_ingress" {
  yaml_body = <<YAML
apiVersion: crd.projectcalico.org/v1
kind: NetworkPolicy
metadata:
  name: metrics-ingress
  namespace: ${var.metrics_ns}
spec:
  order: 10
  selector: app.kubernetes.io/name == 'grafana'
  types:
    - Ingress
  ingress:
    - action: Allow
      protocol: TCP
      source:
        namespaceSelector: kubernetes.io/metadata.name == 'kube-system'
        selector: app.kubernetes.io/name == 'rke2-ingress-nginx'
      destination:
        ports:
          - 3000
  YAML

  depends_on = [kubernetes_namespace.portainer_ns]
}

resource "kubectl_manifest" "metrics_egress" {
  yaml_body = <<YAML
apiVersion: crd.projectcalico.org/v1
kind: GlobalNetworkPolicy
metadata:
  name: metrics-egress
spec:
  namespaceSelector: kubernetes.io/metadata.name == '${var.metrics_ns}'
  selector: app.kubernetes.io/name == 'grafana'
  types:
    - Egress
  egress:
    - action: Allow
      protocol: TCP
      destination:
        ports:
          - 443
        domains:
          - grafana.com
  YAML
}

resource "kubectl_manifest" "prometheus_egress" {
  yaml_body = <<YAML
apiVersion: crd.projectcalico.org/v1
kind: NetworkPolicy
metadata:
  name: prometheus-egress
  namespace: ${var.metrics_ns}
spec:
  order: 10
  namespaceSelector: kubernetes.io/metadata.name == '${var.metrics_ns}'
  types:
    - Egress
  egress:
    - action: Allow
      protocol: TCP
      destination:
        namespaceSelector: kubernetes.io/metadata.name == 'kube-system'
        selector: app.kubernetes.io/name == 'rke2-coredns'
        ports:
          - 9153
  YAML

  depends_on = [kubernetes_namespace.metrics_ns]
}

resource "kubectl_manifest" "prometheus_coredns" {
  yaml_body = <<YAML
apiVersion: crd.projectcalico.org/v1
kind: NetworkPolicy
metadata:
  name: prometheus-coredns
  namespace: kube-system
spec:
  order: 10
  namespaceSelector: kubernetes.io/metadata.name == 'kube-system'
  selector: app.kubernetes.io/name == 'rke2-coredns'
  types:
    - Ingress
  ingress:
    - action: Allow
      protocol: TCP
      destination:
        ports:
          - 9153
      source:
        namespaceSelector: kubernetes.io/metadata.name == '${var.metrics_ns}'
  YAML

  depends_on = [kubernetes_namespace.metrics_ns]
}
