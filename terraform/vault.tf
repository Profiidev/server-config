variable "vault_svc" {
  type    = string
  default = "vault"
}

variable "vault_cert_var" {
  type    = string
  default = "vault-server-tls"
}

variable "vault_cert_prop" {
  type    = string
  default = "vault"
}

variable "vault_csr" {
  type    = string
  default = "vault-csr"
}

locals {
  csr_conf_content = templatefile("${path.module}/../certs/csr.conf.tftpl", {
    namespace = var.secrets_ns
    svc       = var.vault_svc
  })
}

resource "local_file" "vault_csr_conf" {
  content  = local.csr_conf_content
  filename = "${path.module}/../certs/csr.conf"
}

resource "null_resource" "vault_generate_csr" {
  depends_on = [local_file.vault_csr_conf]

  provisioner "local-exec" {
    command = <<EOT
      openssl genrsa -out ${path.module}/../certs/vault.key 2048
      openssl req -new -key ${path.module}/../certs/vault.key \
       -subj "/CN=system:node:${var.vault_svc}.${var.secrets_ns}.svc/O=system:nodes" \
       -out ${path.module}/../certs/vault.csr -config ${path.module}/../certs/csr.conf
    EOT
  }
}

data "local_file" "vault_key" {
  depends_on = [null_resource.vault_generate_csr]
  filename   = "${path.module}/../certs/vault.key"
}


data "local_file" "vault_csr" {
  depends_on = [null_resource.vault_generate_csr]
  filename   = "${path.module}/../certs/vault.csr"
}

resource "kubernetes_certificate_signing_request_v1" "vault_csr" {
  auto_approve = true

  metadata {
    name = var.vault_csr
  }

  spec {
    request     = data.local_file.vault_csr.content
    signer_name = "kubernetes.io/kubelet-serving"
    usages = [
      "digital signature",
      "key encipherment",
      "server auth"
    ]
  }

  depends_on = [data.local_file.vault_csr]
}

resource "kubernetes_secret_v1" "vault_tls_secret" {
  metadata {
    name      = var.vault_cert_var
    namespace = var.secrets_ns
  }
  type = "generic"
  binary_data = {
    "${var.vault_cert_prop}.crt" = base64encode(kubernetes_certificate_signing_request_v1.vault_csr.certificate)
    "${var.vault_cert_prop}.key" = data.local_file.vault_key.content_base64
    "${var.vault_cert_prop}.ca"  = base64encode(data.external.cluster_ca_cert.result["ca"])
  }

  depends_on = [
    kubernetes_certificate_signing_request_v1.vault_csr,
    data.local_file.vault_key,
    data.external.cluster_ca_cert
  ]
}

data "external" "vault_init" {
  program = ["bash", "-c", <<EOT
    kubectl exec --stdin=true --tty=true vault-0 -n ${var.secrets_ns} -- vault operator init | \
    awk -F ': ' '
      /Unseal Key 1:/ {print "key-1="$2}
      /Unseal Key 2:/ {print "key-2="$2}
      /Unseal Key 3:/ {print "key-3="$2}
      /Unseal Key 4:/ {print "key-4="$2}
      /Unseal Key 5:/ {print "key-5="$2}
      /Initial Root Token:/ {print "token="$2}
    ' | jq -R -s '
      split("\\n") | map(select(. != "")) |
      map(split("=") | { (.[0]): .[1] }) | add
    '
  EOT
  ]

  depends_on = [helm_release.vault]
}

resource "kubernetes_secret_v1" "vault_unseal_key" {
  for_each = {
    for key in ["key-1", "key-2", "key-3", "key-4", "key-5"] :
    key => data.external.vault_init.result[key]
  }

  metadata {
    name      = "vault-unseal-${each.key}"
    namespace = var.secrets_ns
  }

  data = {
    key = each.value
  }

  type       = "Opaque"
  depends_on = [data.external.vault_init]
}

resource "null_resource" "vault_initial_unseal" {
  provisioner "local-exec" {
    command = <<-EOT
      kubectl exec --stdin=true --tty=true vault-0 -n ${var.secrets_ns} -- vault operator unseal "${data.external.vault_init.result["key-1"]}"
      kubectl exec --stdin=true --tty=true vault-0 -n ${var.secrets_ns} -- vault operator unseal "${data.external.vault_init.result["key-2"]}"
      kubectl exec --stdin=true --tty=true vault-0 -n ${var.secrets_ns} -- vault operator unseal "${data.external.vault_init.result["key-3"]}"
      kubectl exec --stdin=true --tty=true vault-0 -n ${var.secrets_ns} -- vault login "${data.external.vault_init.result["token"]}"
    EOT
  }

  depends_on = [data.external.vault_init]
}

output "vault_unseal_key" {
  value = [for s in kubernetes_secret_v1.vault_unseal_key : s.metadata[0].name]
}

output "vault_token" {
  value = data.external.vault_init.result["token"]
}
