data "http" "gateway_api" {
  url = "https://github.com/kubernetes-sigs/gateway-api/releases/download/${var.gateway_api_version}/experimental-install.yaml"
}

data "kubectl_file_documents" "gateway_api" {
  content = data.http.gateway_api.response_body
}

resource "kubectl_manifest" "gateway_api" {
  for_each = data.kubectl_file_documents.gateway_api.manifests
  yaml_body = each.value

  server_side_apply = true
  wait = true
  force_conflicts = true
}
