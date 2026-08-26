data "http" "gateway_api" {
  url = "https://github.com/kubernetes-sigs/gateway-api/releases/download/${var.gateway_api_version}/experimental-install.yaml"
}

data "kubectl_file_documents" "gateway_api" {
  content = data.http.gateway_api.response_body
}

locals {
  # CRDs already shipped and owned by the rke2-traefik-crd helm chart (kube-system
  # HelmChartConfig has kubernetesGateway.enabled/experimentalChannel = true).
  # Must stay excluded here or a future chart bump that adds one of these fights
  # helm for ownership since this resource applies without helm's release labels.
  rke2_managed_gateway_crds = toset([
    "backendtlspolicies.gateway.networking.k8s.io",
    "gatewayclasses.gateway.networking.k8s.io",
    "gateways.gateway.networking.k8s.io",
    "grpcroutes.gateway.networking.k8s.io",
    "httproutes.gateway.networking.k8s.io",
    "referencegrants.gateway.networking.k8s.io",
    "tlsroutes.gateway.networking.k8s.io",
  ])

  gateway_api_manifests = {
    for k, v in data.kubectl_file_documents.gateway_api.manifests :
    k => v
    if !contains(local.rke2_managed_gateway_crds, try(yamldecode(v).metadata.name, ""))
  }
}

resource "kubectl_manifest" "gateway_api" {
  for_each  = local.gateway_api_manifests
  yaml_body = each.value

  server_side_apply = true
  wait              = true
  force_conflicts   = true
}
