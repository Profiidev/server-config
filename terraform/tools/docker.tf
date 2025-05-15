resource "kubernetes_namespace" "docker_ns" {
  metadata {
    name = var.docker_ns
    labels = {
      "${var.cloudflare_cert_label.key}" = var.cloudflare_cert_label.value
      "${var.secret_store_label.key}"    = var.secret_store_label.value
    }
  }
}

module "seafile" {
  source = "../modules/docker"

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
  https                  = false

  depends_on = [kubernetes_namespace.docker_ns]
}

module "wings" {
  source = "../modules/docker"

  name                   = "wings"
  port                   = 443
  cert_issuer            = var.cert_issuer_prod
  cloudflare             = false
  cloudflare_ca_cert_var = var.cloudflare_ca_cert_var
  cloudflare_cert_var    = var.cloudflare_cert_var
  ip                     = "192.168.202.10"
  domain                 = "wings.profidev.io"
  ingress_class          = var.ingress_class
  namespace              = var.docker_ns
  https                  = false

  depends_on = [kubernetes_namespace.docker_ns]
}

module "panel" {
  source = "../modules/docker"

  name                   = "panel"
  port                   = 80
  cert_issuer            = var.cert_issuer_prod
  cloudflare             = true
  cloudflare_ca_cert_var = var.cloudflare_ca_cert_var
  cloudflare_cert_var    = var.cloudflare_cert_var
  ip                     = "192.168.201.10"
  domain                 = "panel.profidev.io"
  ingress_class          = var.ingress_class
  namespace              = var.docker_ns
  https                  = false

  depends_on = [kubernetes_namespace.docker_ns]
}

module "hausfix" {
  source = "../modules/docker"

  name                   = "hausfix"
  port                   = 3000
  cert_issuer            = var.cert_issuer_prod
  cloudflare             = true
  cloudflare_ca_cert_var = var.cloudflare_ca_cert_var
  cloudflare_cert_var    = var.cloudflare_cert_var
  ip                     = "192.168.210.10"
  domain                 = "hausfix.profidev.io"
  ingress_class          = var.ingress_class
  namespace              = var.docker_ns
  https                  = false

  depends_on = [kubernetes_namespace.docker_ns]
}

module "hausfix-backend" {
  source = "../modules/docker"

  name                   = "hausfix-backend"
  port                   = 42069
  cert_issuer            = var.cert_issuer_prod
  cloudflare             = true
  cloudflare_ca_cert_var = var.cloudflare_ca_cert_var
  cloudflare_cert_var    = var.cloudflare_cert_var
  ip                     = "192.168.210.20"
  domain                 = "hausfix-backend.profidev.io"
  ingress_class          = var.ingress_class
  namespace              = var.docker_ns
  https                  = false

  depends_on = [kubernetes_namespace.docker_ns]
}
