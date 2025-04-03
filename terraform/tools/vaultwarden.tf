resource "kubernetes_namespace" "vaultwarden_ns" {
  metadata {
    name = var.vaultwarden_ns
    labels = {
      "${var.cloudflare_cert_label.key}" = var.cloudflare_cert_label.value
      "${var.secret_store_label.key}"    = var.secret_store_label.value
    }
  }
}

resource "helm_release" "vaultwarden" {
  name       = "vaultwarden"
  repository = "https://guerzon.github.io/vaultwarden"
  chart      = "vaultwarden"
  version    = "0.31.8"
  namespace  = var.vaultwarden_ns

  values = [templatefile("${path.module}/templates/vaultwarden.values.tftpl", {
    storage_class          = var.storage_class
    ingress_class          = var.ingress_class
    cloudflare_cert_var    = var.cloudflare_cert_var
    cloudflare_ca_cert_var = var.cloudflare_ca_cert_var
    namespace              = var.vaultwarden_ns
  })]

  depends_on = [kubernetes_namespace.vaultwarden_ns]
}

resource "kubectl_manifest" "vaultwarden_ingress" {
  yaml_body = <<YAML
apiVersion: crd.projectcalico.org/v1
kind: NetworkPolicy
metadata:
  name: vaultwarden-ingress
  namespace: ${var.vaultwarden_ns}
spec:
  order: 10
  selector: app.kubernetes.io/name == 'vaultwarden'
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
          - 8080
  YAML

  depends_on = [kubernetes_namespace.vaultwarden_ns]
}

resource "kubectl_manifest" "vaultwarden_secrets" {
  yaml_body = <<YAML
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: vaultwarden
  namespace: ${var.vaultwarden_ns}
spec:
  refreshInterval: 15s
  secretStoreRef:
    name: ${var.cluster_secret_store}
    kind: ClusterSecretStore
  target:
    name: vaultwarden
  dataFrom:
  - extract:
      key: apps/vaultwarden
  YAML

  depends_on = [kubernetes_namespace.vaultwarden_ns]
}

resource "kubectl_manifest" "vaultwarden_egress" {
  yaml_body = <<YAML
apiVersion: crd.projectcalico.org/v1
kind: GlobalNetworkPolicy
metadata:
  name: vaultwarden-egress
spec:
  namespaceSelector: kubernetes.io/metadata.name == '${var.vaultwarden_ns}'
  selector: app.kubernetes.io/name == 'vaultwarden'
  types:
    - Egress
  egress:
    - action: Allow
      protocol: TCP
      destination:
        ports:
          - 443
        domains:
          - *.bitwarden.eu
          - *.bitwarden.com
  YAML

  depends_on = [kubernetes_namespace.everest_system_ns]
}
