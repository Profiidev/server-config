// Load Balancer
resource "helm_release" "metallb" {
  name       = "metallb"
  repository = "https://metallb.github.io/metallb"
  chart      = "metallb"
  version    = "0.14.9"
  namespace  = var.lb-ns

  depends_on = [kubernetes_namespace.lb-ns]
}

// Storage
resource "helm_release" "longhorn" {
  name       = "longhorn"
  repository = "https://charts.longhorn.io"
  chart      = "longhorn"
  version    = "1.8.1"
  namespace  = var.storage-ns

  depends_on = [kubernetes_namespace.storage-ns]
}

// Proxy
resource "helm_release" "ingress-nginx" {
  name       = "ingress-nginx"
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  version    = "4.12.1"
  namespace  = var.proxy-ns

  values = [templatefile("${path.module}/../helm/ingress-nginx.values.tftpl", {
    ingress_class = var.ingress-class
  })]

  depends_on = [kubernetes_namespace.proxy-ns]
}

// Secrets
resource "helm_release" "vault" {
  name       = "vault"
  repository = "https://helm.releases.hashicorp.com"
  chart      = "vault"
  version    = "0.29.1"
  namespace  = var.secrets-ns

  values = [templatefile("${path.module}/../helm/vault.values.tftpl", {
    cert_var      = var.vault_cert_var
    cert_prop     = var.vault_cert_prop
    storage_class = var.storage-class
  })]

  depends_on = [kubernetes_namespace.secrets-ns]
}

resource "helm_release" "external-secrets" {
  name       = "external-secrets"
  repository = "https://charts.external-secrets.io"
  chart      = "external-secrets"
  version    = "0.15.0"
  namespace  = var.secrets-ns

  values = [templatefile("${path.module}/../helm/external-secrets.values.tftpl", {
    volume       = data.template_file.cluster-ca-cert-volume.rendered
    volume_mount = data.template_file.cluster-ca-cert-volume-mount.rendered
  })]

  depends_on = [kubernetes_namespace.secrets-ns]
}

// Certificate Manager
resource "helm_release" "cert-manager" {
  name       = "cert-manager"
  repository = "https://charts.jetstack.io"
  chart      = "cert-manager"
  version    = "1.17.0"
  namespace  = var.cert-ns

  values = [templatefile("${path.module}/../helm/cert-manager.values.tftpl", {})]

  depends_on = [kubernetes_namespace.cert-ns]
}

// Portainer
resource "helm_release" "portainer" {
  name       = "portainer"
  repository = "https://portainer.github.io/k8s"
  chart      = "portainer"
  version    = "1.0.63"
  namespace  = var.portainer-ns

  values = [templatefile("${path.module}/../helm/portainer.values.tftpl", {
    namespace              = var.portainer-ns
    cloudflare_ca_cert_var = var.cloudflare-ca-cert-var
    cloudflare_cert_var    = var.cloudflare-cert-var
    ingress_class          = var.ingress-class
  })]

  depends_on = [kubernetes_namespace.portainer-ns]
}
