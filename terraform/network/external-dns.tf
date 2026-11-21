resource "kubernetes_namespace" "external-dns" {
  metadata {
    name = var.external_dns_ns
  }
}

resource "helm_release" "external-dns" {
  name       = "external-dns"
  repository = "https://kubernetes-sigs.github.io/external-dns"
  chart      = "external-dns"
  namespace  = kubernetes_namespace.external-dns.metadata[0].name
  version    = "1.23.0"

  values = [
    templatefile("${path.module}/templates/external-dns.values.tftpl", {
    })
  ]

  depends_on = [kubectl_manifest.external_dns_secrets]
}

resource "kubectl_manifest" "external_dns_secrets" {
  yaml_body = <<YAML
apiVersion: external-secrets.io/v1
kind: ExternalSecret
metadata:
  name: external-dns
  namespace: ${kubernetes_namespace.external-dns.metadata[0].name}
spec:
  refreshInterval: 5m
  secretStoreRef:
    name: ${var.cluster_secret_store}
    kind: ClusterSecretStore
  target:
    name: external-dns
  dataFrom:
  - extract:
      key: certs/cert-manager
  YAML
}

module "external_np_external_dns" {
  source = "../modules/external-np"

  namespace = var.external_dns_ns

  depends_on = [kubernetes_namespace.external-dns]
}

locals {
  nodes = {
    node1 = var.node1
    node2 = var.node2
    node3 = var.node3
  }

  # domain => DNSEndpoint name prefix (empty for profidev.io keeps existing names)
  cluster_domains = {
    "profidev.io" = ""
    "buerger.sh"  = "buerger-"
  }
}

resource "kubectl_manifest" "cluster_a_records" {
  for_each = local.cluster_domains

  yaml_body = <<YAML
apiVersion: externaldns.k8s.io/v1alpha1
kind: DNSEndpoint
metadata:
  name: ${each.value}cluster-a-records
spec:
  endpoints:
    - dnsName: cluster.${each.key}
      recordType: A
      targets:
        %{for ip in values(local.nodes)}
        - ${ip}
        %{endfor}
  YAML

  depends_on = [helm_release.external-dns]
}

resource "kubectl_manifest" "node_a_records" {
  for_each = {
    for pair in setproduct(keys(local.nodes), keys(local.cluster_domains)) :
    "${pair[0]}.${pair[1]}" => { node = pair[0], domain = pair[1] }
  }

  yaml_body = <<YAML
apiVersion: externaldns.k8s.io/v1alpha1
kind: DNSEndpoint
metadata:
  name: ${local.cluster_domains[each.value.domain]}${each.value.node}-a-records
spec:
  endpoints:
    - dnsName: ${each.value.node}.cluster.${each.value.domain}
      recordType: A
      targets:
        - ${local.nodes[each.value.node]}
  YAML

  depends_on = [helm_release.external-dns]
}
