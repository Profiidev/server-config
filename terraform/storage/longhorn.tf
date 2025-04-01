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
    count         = 1,
    ingress_class = var.ingress_class
  })]

  depends_on = [kubernetes_namespace.storage_ns]
}

resource "kubectl_manifest" "k8s_api_egress" {
  yaml_body = <<YAML
apiVersion: crd.projectcalico.org/v1
kind: NetworkPolicy
metadata:
  name: k8s-api-egress
  namespace: ${var.storage_ns}
spec:
  order: 10
  selector: all()
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
  YAML
}

resource "kubectl_manifest" "ui_frontend_backend" {
  yaml_body = <<YAML
apiVersion: crd.projectcalico.org/v1
kind: NetworkPolicy
metadata:
  name: iu-frontend-backend
  namespace: longhorn-system
spec:
  order: 10
  selector: app == 'longhorn-ui'
  types:
    - Egress
  egress:
    - action: Allow
      protocol: TCP
      destination:
        namespaceSelector: kubernetes.io/metadata.name == 'longhorn-system'
        selector: app == 'longhorn-manager'
        ports:
          - 9500
  YAML
}
