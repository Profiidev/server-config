resource "kubectl_manifest" "ghcr_profidev_secret" {
  yaml_body = <<YAML
apiVersion: external-secrets.io/v1beta1
kind: ClusterExternalSecret
metadata:
  name: ${var.ghcr_profidev}
spec:
  externalSecretName: ${var.ghcr_profidev}
  namespaceSelectors:
    - matchLabels:
        ${var.ghcr_profidev_label.key}: "${var.ghcr_profidev_label.value}"
  refreshTime: 15s
  externalSecretSpec:
    target:
      name: ${var.ghcr_profidev}
      template:
        type: kubernetes.io/dockerconfigjson
        data:
          .dockerconfigjson: '{"auths":{"https://ghcr.io":{"username":"profiidev","password":"{{ .token }}","auth":"{{ printf "profiidev:%s" .token | b64enc }}"}}}'
    refreshInterval: 15s
    secretStoreRef:
      name: ${var.cluster_secret_store}
      kind: ClusterSecretStore
    data:
    - secretKey: token
      remoteRef:
        key: docker/ghcr
        property: profidev
  YAML

  depends_on = [helm_release.external_secrets]
}
