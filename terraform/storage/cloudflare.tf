resource "kubectl_manifest" "cloudflare_cert" {
  for_each = tomap({
    "${var.cloudflare_cert_var}"    = ["tls.crt", "tls.key"]
    "${var.cloudflare_ca_cert_var}" = ["ca.crt"]
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
  refreshTime: 5m
  externalSecretSpec:
    target:
      name: ${each.key}
      template:
        type: ${var.cloudflare_cert_var == each.key ? "kubernetes.io/tls" : "Opaque"}
    refreshInterval: 5m
    secretStoreRef:
      name: ${var.cluster_secret_store}
      kind: ClusterSecretStore
    data:
      %{for value in each.value}
      - secretKey: ${value}
        remoteRef:
          key: certs/cloudflare
          property: ${value}
      %{endfor}
  YAML

  depends_on = [
    helm_release.external_secrets
  ]
}
