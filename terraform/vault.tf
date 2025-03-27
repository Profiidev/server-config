locals {
  csr_conf_content = templatefile("${path.module}/../certs/csr.conf.tftpl", { namespace = var.secrets-ns })
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
      openssl req -new -key ${path.module}/../certs/vault.key -subj "/CN=system:node:vault-server-tls.${var.secrets-ns}.svc/O=system:nodes" -out ${path.module}/../certs/vault.csr -config ${path.module}/../certs/csr.conf
    EOT
  }
}

resource "null_resource" "vault_read_csr_base64" {
  depends_on = [null_resource.vault_generate_csr]

  provisioner "local-exec" {
    command = "cat ${path.module}/../certs/vault.csr | base64 | tr -d '\n' > ${path.module}/../certs/vault.b64.csr"
  }
}

data "local_file" "vault_csr_base64" {
  depends_on = [null_resource.vault_read_csr_base64]
  filename   = "${path.module}/../certs/vault.b64.csr"
}

variable "vault_csr" {
  type    = string
  default = "vault-csr"
}

resource "kubernetes_certificate_signing_request" "vault_csr" {
  metadata {
    name = var.vault_csr
  }

  spec {
    request     = data.local_file.vault_csr_base64
    signer_name = "kubernetes.io/kubelet-serving"
    usages = [
      "digital signature",
      "key encipherment",
      "server auth"
    ]
  }

  depends_on = [data.local_file.vault_csr_base64]
}

resource "null_resource" "vault_approve_csr" {
  depends_on = [kubernetes_certificate_signing_request.vault_csr]

  provisioner "local-exec" {
    command = "kubectl certificate approve ${var.vault_csr}"
  }
}

data "external" "vault_read_signed_cert" {
  depends_on = [null_resource.vault_approve_csr]

  program = ["bash", "-c", <<EOT
    for i in {1..10}; do
      cert=$(kubectl get csr ${var.vault_csr} -o jsonpath='{.status.certificate}')
      if [ ! -z "$cert" ]; then echo "{\"certificate\": \"$cert\"}"; exit 0; fi
      sleep 2
    done
    echo "{\"certificate\": \"\"}"
  EOT
  ]
}

resource "local_file" "vault_cert" {
  depends_on = [data.external.vault_read_signed_cert]

  content  = base64decode(data.external.read_signed_cert.result["certificate"])
  filename = "${path.module}/../certs/vault.crt"
}
