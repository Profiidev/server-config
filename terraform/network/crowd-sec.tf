resource "kubernetes_namespace" "crowdsec" {
  metadata {
    name = var.crowdsec_ns
    labels = {
      "${var.secret_store_label.key}" = var.secret_store_label.value
    }
  }
}

resource "helm_release" "crowdsec" {
  name       = "crowdsec"
  repository = "https://crowdsecurity.github.io/helm-charts"
  chart      = "crowdsec"
  namespace  = var.crowdsec_ns
  version    = "0.20.1"

  values = [
    templatefile("${path.module}/templates/crowdsec.values.tftpl", {
    })
  ]

  depends_on = [kubernetes_namespace.crowdsec]
}

resource "kubectl_manifest" "crowdsec_secrets" {
  yaml_body = <<YAML
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: crowdsec
  namespace: ${var.crowdsec_ns}
spec:
  refreshInterval: 15s
  secretStoreRef:
    name: ${var.cluster_secret_store}
    kind: ClusterSecretStore
  target:
    name: crowdsec
  dataFrom:
  - extract:
      key: certs/crowdsec
  YAML

  depends_on = [kubernetes_namespace.crowdsec]
}

resource "kubectl_manifest" "crowdsec_egress" {
  yaml_body = <<YAML
apiVersion: crd.projectcalico.org/v1
kind: NetworkPolicy
metadata:
  name: crowdsec-egress
  namespace: ${var.crowdsec_ns}
spec:
  order: 10
  namespaceSelector: kubernetes.io/metadata.name == '${var.crowdsec_ns}'
  selector: k8s-app == 'crowdsec'
  types:
    - Egress
    - Ingress
  egress:
    - action: Allow
      protocol: TCP
      destination:
        notNets:
          - 10.0.0.0/8
          - 172.16.0.0/12
          - 192.168.0.0/16
        ports:
          - 443
  ingress:
    - action: Allow
      protocol: TCP
      source:
        namespaceSelector: kubernetes.io/metadata.name == 'kube-system'
        selector: app.kubernetes.io/name == 'rke2-ingress-nginx'
      destination:
        ports:
          - 8080
  YAML

  depends_on = [kubernetes_namespace.crowdsec]
}

resource "kubectl_manifest" "crowdsec_ns" {
  yaml_body = <<YAML
apiVersion: crd.projectcalico.org/v1
kind: NetworkPolicy
metadata:
  name: crowdsec-namespace
  namespace: ${var.crowdsec_ns}
spec:
  order: 10
  namespaceSelector: kubernetes.io/metadata.name == '${var.crowdsec_ns}'
  types:
    - Egress
    - Ingress
  egress:
    - action: Allow
      protocol: TCP
      destination:
        namespaceSelector: kubernetes.io/metadata.name == '${var.crowdsec_ns}'
  ingress:
    - action: Allow
      protocol: TCP
      source:
        namespaceSelector: kubernetes.io/metadata.name == '${var.crowdsec_ns}'
  YAML

  depends_on = [kubernetes_namespace.crowdsec]
}
