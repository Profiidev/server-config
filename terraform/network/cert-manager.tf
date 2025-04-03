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

resource "kubectl_manifest" "cert_manager_k8s_api_egress" {
  yaml_body = <<YAML
apiVersion: crd.projectcalico.org/v1
kind: NetworkPolicy
metadata:
  name: k8s-api-egress
  namespace: ${var.cert_ns}
spec:
  order: 10
  selector: app.kubernetes.io/name == 'cainjector' || app.kubernetes.io/name == 'cert-manager' || app.kubernetes.io/name == 'webhook'
  types:
    - Egress
  egress:
    - action: Allow
      protocol: TCP
      destination:
        nets:
          - 194.164.200.60/32
        ports:
          - 6443
  YAML

  depends_on = [kubernetes_namespace.cert_ns]
}

resource "kubernetes_network_policy_v1" "cert_ns" {
  metadata {
    name      = "cert-internal"
    namespace = var.cert_ns
  }

  spec {
    ingress {
      from {
        pod_selector {}
      }
    }
    pod_selector {

    }
    policy_types = ["Ingress"]
  }
}

resource "kubectl_manifest" "cert_manager_egress" {
  yaml_body = <<YAML
apiVersion: crd.projectcalico.org/v1
kind: GlobalNetworkPolicy
metadata:
  name: cert-manager-egress
spec:
  namespaceSelector: kubernetes.io/metadata.name == '${var.cert_ns}'
  types:
    - Egress
  egress:
    - action: Allow
      protocol: TCP
      destination:
        ports:
          - 443
          - 80
        domains:
          - "*.letsencrypt.org"
          - "*.profidev.io"
          - "profidev.io"
  YAML

  depends_on = [kubernetes_namespace.cert_ns]
}
