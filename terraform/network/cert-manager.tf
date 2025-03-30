resource "kubernetes_namespace" "cert_ns" {
  metadata {
    name = var.cert_ns
  }
}

resource "helm_release" "cert_manager" {
  name       = "cert-manager"
  repository = "https://charts.jetstack.io"
  chart      = "cert-manager"
  version    = "1.17.0"
  namespace  = var.cert_ns

  values = [templatefile("${path.module}/templates/cert-manager.values.tftpl", {})]

  depends_on = [kubernetes_namespace.cert_ns]
}

resource "kubectl_manifest" "cert_issuer" {
  for_each = tomap({
    staging = "https://acme-staging-v02.api.letsencrypt.org/directory"
    prod    = "https://acme-v02.api.letsencrypt.org/directory"
  })

  yaml_body = <<YAML
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: ${each.key == "prod" ? var.cert_issuer_prod : var.cert_issuer_staging}
spec:
  acme:
    email: ${var.email}
    server: ${each.value}
    privateKeySecretRef:
      name: letsencrypt-${each.key}-issuer-account-key
    solvers:
      - http01:
          ingress:
            ingressClassName: ${var.ingress_class}
  YAML

  depends_on = [helm_release.cert_manager]
}
