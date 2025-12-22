resource "kubernetes_namespace" "crowdsec" {
  metadata {
    name = var.crowdsec_ns
  }
}

resource "random_password" "bouncer_key" {
  min_lower   = 1
  min_upper   = 1
  min_numeric = 1
  min_special = 1
  length      = 32
}

resource "helm_release" "crowdsec" {
  name       = "crowdsec"
  repository = "https://crowdsecurity.github.io/helm-charts"
  chart      = "crowdsec"
  namespace  = var.crowdsec_ns
  version    = "0.20.1"

  values = [
    templatefile("${path.module}/templates/crowdsec.values.tftpl", {
      traefik_bouncer_key = random_password.bouncer_key.result
    })
  ]

  depends_on = [kubernetes_namespace.crowdsec]
}

resource "kubectl_manifest" "crowdsec_secrets" {
  yaml_body = <<YAML
apiVersion: external-secrets.io/v1
kind: ExternalSecret
metadata:
  name: crowdsec
  namespace: ${var.crowdsec_ns}
spec:
  refreshInterval: 5m
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

module "external_np_crowdsec" {
  source = "../modules/external-np"

  namespace = var.crowdsec_ns

  depends_on = [kubernetes_namespace.crowdsec]
}
