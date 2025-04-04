locals {
  csr_conf_content = templatefile("${path.module}/templates/csr.conf.tftpl", {
    namespace = var.secrets_ns
    svc       = var.vault_svc
  })
}

resource "local_file" "vault_csr_conf" {
  content  = local.csr_conf_content
  filename = "${path.module}/certs/csr.conf"
}

resource "null_resource" "vault_generate_csr" {
  depends_on = [local_file.vault_csr_conf]

  provisioner "local-exec" {
    command = <<EOT
      openssl genrsa -out ${path.module}/certs/vault.key 2048
      openssl req -new -key ${path.module}/certs/vault.key \
       -subj "/CN=system:node:${var.vault_svc}.${var.secrets_ns}.svc/O=system:nodes" \
       -out ${path.module}/certs/vault.csr -config ${path.module}/certs/csr.conf
    EOT
  }
}

data "local_file" "vault_key" {
  depends_on = [null_resource.vault_generate_csr]
  filename   = "${path.module}/certs/vault.key"
}


data "local_file" "vault_csr" {
  depends_on = [null_resource.vault_generate_csr]
  filename   = "${path.module}/certs/vault.csr"
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
}
