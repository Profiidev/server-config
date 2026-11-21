resource "kubectl_manifest" "cloudflare_cert" {
  for_each = tomap({
    "${var.cloudflare_cert_var}"            = { key = "certs/cloudflare", tls = true, props = ["tls.crt", "tls.key"] }
    "${var.cloudflare_ca_cert_var}"         = { key = "certs/cloudflare", tls = false, props = ["ca.crt"] }
    "${var.cloudflare_buerger_cert_var}"    = { key = "certs/cloudflare-buerger", tls = true, props = ["tls.crt", "tls.key"] }
    "${var.cloudflare_buerger_ca_cert_var}" = { key = "certs/cloudflare-buerger", tls = false, props = ["ca.crt"] }
  })

  yaml_body = <<YAML
apiVersion: external-secrets.io/v1
kind: ClusterExternalSecret
metadata:
  name: ${each.key}
spec:
  externalSecretName: ${each.key}
  namespaceSelectors:
    - matchLabels: {}
  refreshTime: 60m
  externalSecretSpec:
    target:
      name: ${each.key}
      template:
        type: ${each.value.tls ? "kubernetes.io/tls" : "Opaque"}
    refreshInterval: 60m
    secretStoreRef:
      name: ${var.cluster_secret_store}
      kind: ClusterSecretStore
    data:
      %{for value in each.value.props}
      - secretKey: ${value}
        remoteRef:
          key: ${each.value.key}
          property: ${value}
      %{endfor}
  YAML

  depends_on = [
    helm_release.external_secrets
  ]
}
