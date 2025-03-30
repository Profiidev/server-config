resource "kubectl_manifest" "cloudflare_cert" {
  for_each = tomap({
    "${var.cloudflare_cert_var}"    = ["tls.crt", "tls.key"]
    "${var.cloudflare_ca_cert_var}" = ["ca.crt"]
  })

  yaml_body = <<YAML
apiVersion: external-secrets.io/v1beta1
kind: ClusterExternalSecret
metadata:
  name: ${each.key}
spec:
  externalSecretName: ${each.key}
  namespaceSelectors:
    - matchLabels:
        ${var.cloudflare_cert_label.key}: "${var.cloudflare_cert_label.value}"
  refreshTime: 15s

  externalSecretSpec:
    target:
      name: ${each.key}
    refreshInterval: 15s
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
}
