resource "null_resource" "download" {
  triggers = {
    config_hash = sha256(jsonencode(var.url))
  }

  provisioner "local-exec" {
    command = var.download ? "curl -o ${path.module}/dashboards/${var.name}.json ${var.url}" : "echo 0"
  }
}

data "local_file" "json" {
  depends_on = [null_resource.download]
  filename   = "${path.module}/dashboards/${var.name}.json"
}

resource "kubernetes_config_map_v1" "config_map" {
  metadata {
    name = var.name
    labels = {
      "grafana_dashboard" = "1"
    }
    namespace = var.namespace
  }

  data = {
    "${var.name}.json" = data.local_file.json.content
  }
}
