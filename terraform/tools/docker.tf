resource "kubernetes_namespace" "docker_ns" {
  metadata {
    name = var.docker_ns
  }
}

module "seafile" {
  source = "./docker"

  name                   = "seafile"
  port                   = 80
  cert_issuer            = var.cert_issuer_prod
  cloudflare             = false
  cloudflare_ca_cert_var = var.cloudflare_ca_cert_var
  cloudflare_cert_var    = var.cloudflare_cert_var
  ip                     = "192.168.200.10"
  domain                 = "cloud.profidev.io"
  ingress_class          = var.ingress_class
  namespace              = var.docker_ns

  depends_on = [kubernetes_namespace.docker_ns]
}
