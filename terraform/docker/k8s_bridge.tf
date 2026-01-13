resource "kubernetes_namespace" "docker" {
  metadata {
    name = var.docker_ns
  }
}

module "wings" {
  source = "../modules/docker"

  name                   = "wings"
  port                   = 594
  cert_issuer            = var.cert_issuer_prod
  cloudflare             = false
  cloudflare_ca_cert_var = var.cloudflare_ca_cert_var
  cloudflare_cert_var    = var.cloudflare_cert_var
  ip                     = var.k8s_api
  domain                 = "wings.profidev.io"
  ingress_class          = var.ingress_class
  namespace              = var.docker_ns
  https                  = false

  depends_on = [kubernetes_namespace.docker]
}

module "panel" {
  source = "../modules/docker"

  name                   = "panel"
  port                   = 593
  cert_issuer            = var.cert_issuer_prod
  cloudflare             = true
  cloudflare_ca_cert_var = var.cloudflare_ca_cert_var
  cloudflare_cert_var    = var.cloudflare_cert_var
  ip                     = var.k8s_api
  domain                 = "panel.profidev.io"
  ingress_class          = var.ingress_class
  namespace              = var.docker_ns
  https                  = false

  depends_on = [kubernetes_namespace.docker]
}

module "pl_wings" {
  source = "../modules/docker"

  name                   = "pl-wings"
  port                   = 794
  cert_issuer            = var.cert_issuer_prod
  cloudflare             = false
  cloudflare_ca_cert_var = var.cloudflare_ca_cert_var
  cloudflare_cert_var    = var.cloudflare_cert_var
  ip                     = var.k8s_api
  domain                 = "pl-wings.profidev.io"
  ingress_class          = var.ingress_class
  namespace              = var.docker_ns
  https                  = false

  depends_on = [kubernetes_namespace.docker]
}

module "pl_panel" {
  source = "../modules/docker"

  name                   = "pelican"
  port                   = 793
  cert_issuer            = var.cert_issuer_prod
  cloudflare             = true
  cloudflare_ca_cert_var = var.cloudflare_ca_cert_var
  cloudflare_cert_var    = var.cloudflare_cert_var
  ip                     = var.k8s_api
  domain                 = "pelican.profidev.io"
  ingress_class          = var.ingress_class
  namespace              = var.docker_ns
  https                  = false

  depends_on = [kubernetes_namespace.docker]
}
