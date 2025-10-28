data "local_file" "json" {
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
