resource "kubernetes_namespace" "everest_system" {
  metadata {
    name = var.everest_system_ns
  }
}

resource "helm_release" "postgres" {
  name       = "postgres-ui"
  repository = "https://percona.github.io/percona-helm-charts"
  chart      = "everest"
  version    = "1.9.0"
  namespace  = var.everest_system_ns

  values = [templatefile("${path.module}/templates/postgres-ui.values.tftpl", {
    ingress_class          = var.ingress_class
    everest_system_ns      = var.everest_system_ns
    cloudflare_ca_cert_var = var.cloudflare_ca_cert_var
    cloudflare_cert_var    = var.cloudflare_cert_var
  })]

  depends_on = [kubernetes_namespace.everest_system]
}

module "k8s_api_np_everest_system" {
  source = "../modules/k8s-api-np"

  namespace = var.everest_system_ns
  k8s_api   = var.k8s_api

  depends_on = [kubernetes_namespace.everest_system]
}

resource "null_resource" "wait_for_everest_ns" {
  provisioner "local-exec" {
    command = <<EOT
      until kubectl get namespace ${var.everest_ns}; do
        echo "Waiting for namespace ${var.everest_ns} ..."
        sleep 5
      done
    EOT
  }
}

module "k8s_api_np_everest" {
  source = "../modules/k8s-api-np"

  namespace = var.everest_ns
  k8s_api   = var.k8s_api

  depends_on = [null_resource.wait_for_everest_ns]
}
