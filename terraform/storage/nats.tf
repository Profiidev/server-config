resource "kubernetes_namespace" "nats_ns" {
  metadata {
    name = var.nats_ns
  }
}

resource "helm_release" "nats" {
  name       = "nats"
  repository = "https://nats-io.github.io/k8s/helm/charts"
  chart      = "nats"
  version    = "1.3.3"
  namespace  = var.nats_ns

  values = [templatefile("${path.module}/templates/nats.values.tftpl", {
  })]

  depends_on = [kubernetes_namespace.nats_ns]
}

resource "kubectl_manifest" "nats_ns" {
  yaml_body = <<YAML
apiVersion: crd.projectcalico.org/v1
kind: NetworkPolicy
metadata:
  name: nats-namespace
  namespace: ${var.nats_ns}
spec:
  order: 10
  namespaceSelector: kubernetes.io/metadata.name == '${var.nats_ns}'
  types:
    - Egress
    - Ingress
  egress:
    - action: Allow
      destination:
        namespaceSelector: kubernetes.io/metadata.name == '${var.nats_ns}'
  ingress:
    - action: Allow
      source:
        namespaceSelector: kubernetes.io/metadata.name == '${var.nats_ns}'
  YAML

  depends_on = [kubernetes_namespace.nats_ns]
}

resource "kubectl_manifest" "nats_access" {
  yaml_body = <<YAML
apiVersion: crd.projectcalico.org/v1
kind: NetworkPolicy
metadata:
  name: nats-access
  namespace: ${var.nats_ns}
spec:
  order: 10
  selector: app.kubernetes.io/component == 'nats'
  types:
    - Ingress
  ingress:
    - action: Allow
      source:
        namespaceSelector: ${var.nats_access_label.key} == '${var.nats_access_label.value}'
      destination:
        ports:
          - 4222
  YAML

  depends_on = [helm_release.nats]
}
