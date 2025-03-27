// Load Balancer
resource "helm_release" "metallb" {
  name       = "metallb"
  repository = "https://metallb.github.io/metallb"
  chart      = "metallb"
  version    = "0.14.9"
  namespace  = var.lb_ns

  depends_on = [kubernetes_namespace.lb_ns]
}

// Storage
resource "helm_release" "longhorn" {
  name       = "longhorn"
  repository = "https://charts.longhorn.io"
  chart      = "longhorn"
  version    = "1.8.1"
  namespace  = var.storage_ns

  depends_on = [kubernetes_namespace.storage_ns]
}

// Proxy
resource "helm_release" "ingress_nginx" {
  name       = "ingress-nginx"
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  version    = "4.12.1"
  namespace  = var.proxy_ns

  values = [templatefile("${path.module}/../helm/ingress-nginx.values.tftpl", {
    ingress_class = var.ingress_class
  })]

  depends_on = [kubernetes_namespace.proxy_ns]
}

// Secrets
resource "helm_release" "vault" {
  name       = "vault"
  repository = "https://helm.releases.hashicorp.com"
  chart      = "vault"
  version    = "0.29.1"
  namespace  = var.secrets_ns

  values = [templatefile("${path.module}/../helm/vault.values.tftpl", {
    cert_var      = var.vault_cert_var
    cert_prop     = var.vault_cert_prop
    storage_class = var.storage_class
  })]

  depends_on = [
    kubernetes_namespace.secrets_ns,
    kubernetes_secret_v1.vault_tls_secret
  ]
}

resource "helm_release" "external_secrets" {
  name       = "external-secrets"
  repository = "https://charts.external-secrets.io"
  chart      = "external-secrets"
  version    = "0.15.0"
  namespace  = var.secrets_ns

  values = [templatefile("${path.module}/../helm/external-secrets.values.tftpl", {
    volume       = data.template_file.cluster_ca_cert_volume.rendered
    volume_mount = data.template_file.cluster_ca_cert_volume_mount.rendered
  })]

  depends_on = [kubernetes_namespace.secrets_ns]
}

// Certificate Manager
resource "helm_release" "cert_manager" {
  name       = "cert-manager"
  repository = "https://charts.jetstack.io"
  chart      = "cert-manager"
  version    = "1.17.0"
  namespace  = var.cert_ns

  values = [templatefile("${path.module}/../helm/cert-manager.values.tftpl", {})]

  depends_on = [kubernetes_namespace.cert_ns]
}

// Portainer
resource "helm_release" "portainer" {
  name       = "portainer"
  repository = "https://portainer.github.io/k8s"
  chart      = "portainer"
  version    = "1.0.63"
  namespace  = var.portainer_ns

  values = [templatefile("${path.module}/../helm/portainer.values.tftpl", {
    namespace              = var.portainer_ns
    cloudflare_ca_cert_var = var.cloudflare_ca_cert_var
    cloudflare_cert_var    = var.cloudflare_cert_var
    ingress_class          = var.ingress_class
  })]

  depends_on = [kubernetes_namespace.portainer_ns]
}
