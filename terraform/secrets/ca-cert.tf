data "external" "cluster_ca_cert" {
  program = ["bash", "-c", <<EOT
    kubectl config view --raw --minify --flatten \
     -o jsonpath='{.clusters[].cluster.certificate-authority-data}' | base64 -d |\
     jq -R -s '{ca: .}'
  EOT
  ]
}

resource "kubectl_manifest" "cluster_ca_cert" {
  yaml_body = <<YAML
apiVersion: external-secrets.io/v1beta1
kind: ClusterExternalSecret
metadata:
  name: ${var.cluster_ca_cert_var}
spec:
  externalSecretName: ${var.cluster_ca_cert_var}
  namespaceSelectors:
    - matchLabels:
        ${var.cluster_ca_cert_label.key}: "${var.cluster_ca_cert_label.value}"
  refreshTime: 15s

  externalSecretSpec:
    target:
      name: ${var.cluster_ca_cert_var}
    refreshInterval: 15s
    secretStoreRef:
      name: ${var.cluster_secret_store}
      kind: ClusterSecretStore
    data:
      - secretKey: ca.crt
        remoteRef:
          key: certs/cluster
          property: ca.crt
  YAML

  depends_on = [helm_release.external_secrets]
}

resource "kubernetes_secret_v1" "cluster_ca_cert_secret" {
  metadata {
    name      = var.cluster_ca_cert_var
    namespace = var.secrets_ns
  }
  type = "Opaque"
  binary_data = {
    "ca.crt" = base64encode(data.external.cluster_ca_cert.result["ca"])
  }
}

resource "local_file" "ca_crt" {
  filename = "${path.module}/certs/ca.crt"
  content  = data.external.cluster_ca_cert.result["ca"]
}

data "external" "ca_hash" {
  program = ["bash", "-c", <<EOT
    openssl x509 -noout -hash -in ${path.module}/certs/ca.crt | jq -R '{hash: .}'
  EOT
  ]

  depends_on = [local_file.ca_crt]
}

resource "null_resource" "vault_cluster_ca_cert" {
  provisioner "local-exec" {
    command = <<-EOT
      kubectl exec -it --stdin=true --tty=true vault-0 -n ${var.secrets_ns} -- vault kv put \
       -mount="kv" "certs/cluster" ca.crt="${data.external.cluster_ca_cert.result["ca"]}" ${data.external.ca_hash.result["hash"]}.0="${data.external.cluster_ca_cert.result["ca"]}"
    EOT
  }

  depends_on = [null_resource.vault_init_kv]
}
