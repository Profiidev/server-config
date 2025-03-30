resource "null_resource" "user_generate_csr" {
  provisioner "local-exec" {
    command = <<EOT
      openssl genrsa -out ${path.module}/certs/${var.user_name}.key 2048
      openssl req -new -key ${path.module}/certs/${var.user_name}.key \
       -subj "/CN=${var.user_name}" \
       -out ${path.module}/certs/${var.user_name}.csr
    EOT
  }
}

data "local_file" "user_csr" {
  depends_on = [null_resource.user_generate_csr]
  filename   = "${path.module}/certs/${var.user_name}.csr"
}

resource "kubernetes_certificate_signing_request_v1" "user_csr" {
  auto_approve = true

  metadata {
    name = var.user_name
  }

  spec {
    request     = data.local_file.user_csr.content
    signer_name = "kubernetes.io/kube-apiserver-client"
    usages = [
      "client auth",
      "digital signature",
      "key encipherment"
    ]
  }
}

resource "local_file" "user_cert" {
  content  = kubernetes_certificate_signing_request_v1.user_csr.certificate
  filename = "${path.module}/certs/${var.user_name}.crt"
}

resource "null_resource" "kubectl_user" {
  provisioner "local-exec" {
    command = <<EOT
      kubectl config set-credentials ${var.user_name} --client-key=${path.module}/certs/${var.user_name}.key \
       --client-certificate=${path.module}/certs/${var.user_name}.crt --embed-certs=true
    EOT
  }

  depends_on = [local_file.user_cert]
}

resource "kubernetes_cluster_role_binding_v1" "admin_user_binding" {
  metadata {
    name = "${var.admin_group}-${var.user_name}"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = var.admin_group
  }

  subject {
    api_group = "rbac.authorization.k8s.io"
    kind      = "User"
    name      = var.user_name
  }

  depends_on = [
    kubernetes_certificate_signing_request_v1.user_csr
  ]
}
