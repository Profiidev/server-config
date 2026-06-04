resource "kubectl_manifest" "ghcr_profidev_secret" {
  yaml_body = <<YAML
apiVersion: external-secrets.io/v1
kind: ClusterExternalSecret
metadata:
  name: ${var.ghcr_profidev}
spec:
  externalSecretName: ${var.ghcr_profidev}
  namespaceSelectors:
    - matchLabels: {}
  refreshTime: 60m
  externalSecretSpec:
    target:
      name: ${var.ghcr_profidev}
      template:
        type: kubernetes.io/dockerconfigjson
        data:
          .dockerconfigjson: '{"auths":{"https://ghcr.io":{"username":"profiidev","password":"{{ .token }}","auth":"{{ printf "profiidev:%s" .token | b64enc }}"}}}'
    refreshInterval: 60m
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

resource "kubectl_manifest" "inf_git_secret" {
  yaml_body = <<YAML
apiVersion: external-secrets.io/v1
kind: ClusterExternalSecret
metadata:
  name: inf-git
spec:
  externalSecretName: inf-git
  namespaceSelectors:
    - matchLabels: {}
  refreshTime: 60m
  externalSecretSpec:
    target:
      name: inf-git
      template:
        type: kubernetes.io/dockerconfigjson
        data:
          .dockerconfigjson: '{"auths":{"https://inf-docker.fh-rosenheim.de":{"username":"studbuerbe8362","password":"{{ .token }}","auth":"{{ printf "studbuerbe8362:%s" .token | b64enc }}"}}}'
    refreshInterval: 60m
    secretStoreRef:
      name: ${var.cluster_secret_store}
      kind: ClusterSecretStore
    data:
    - secretKey: token
      remoteRef:
        key: docker/inf-git
        property: profidev
  YAML

  depends_on = [helm_release.external_secrets]
}
