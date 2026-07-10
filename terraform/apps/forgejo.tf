resource "kubernetes_namespace" "forgejo" {
  metadata {
    name = var.forgejo_ns
  }
}

resource "helm_release" "forgejo" {
  name       = "forgejo"
  repository = "oci://code.forgejo.org/forgejo-helm"
  chart      = "forgejo"
  version    = "17.1.2"
  namespace  = var.forgejo_ns

  values = [templatefile("${path.module}/templates/forgejo.values.tftpl", {
    cluster_issuer = var.cert_issuer_prod
    ingress_class  = var.ingress_class
  })]

  depends_on = [kubernetes_namespace.forgejo]
}

resource "kubectl_manifest" "forgejo_egress" {
  yaml_body = <<YAML
apiVersion: crd.projectcalico.org/v1
kind: NetworkPolicy
metadata:
  name: forgejo
  namespace: ${var.forgejo_ns}
spec:
  order: 10
  namespaceSelector: kubernetes.io/metadata.name == '${var.forgejo_ns}'
  types:
    - Egress
    - Ingress
  egress:
    - action: Allow
  ingress:
    - action: Allow
  YAML

  depends_on = [kubernetes_namespace.forgejo]
}

resource "kubectl_manifest" "forgejo_ssh" {
  yaml_body = <<YAML
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: forgejo-ssh
  namespace: ${var.forgejo_ns}
spec:
  gatewayClassName: traefik
  listeners:
    - name: ssh
      protocol: TCP
      port: 2222
  YAML

  depends_on = [kubernetes_namespace.forgejo]
}

resource "kubectl_manifest" "forgejo_secret" {
  yaml_body = <<YAML
apiVersion: external-secrets.io/v1
kind: ExternalSecret
metadata:
  name: forgejo-secrets
  namespace: ${var.forgejo_ns}
spec:
  refreshInterval: 5m
  secretStoreRef:
    name: ${var.cluster_secret_store}
    kind: ClusterSecretStore
  target:
    name: forgejo-secrets
  dataFrom:
  - extract:
      key: tools/forgejo
  YAML

  depends_on = [kubernetes_namespace.forgejo]
}
