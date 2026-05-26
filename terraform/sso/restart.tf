resource "null_resource" "restart_for_sso" {
  provisioner "local-exec" {
    command = <<-EOT
      set -euo pipefail

      kubectl rollout restart daemonset -n kube-system rke2-traefik
      kubectl rollout restart deployment -n ${var.argo_ns} argocd-server
      kubectl rollout restart deployment -n ${var.metrics_ns} grafana
    EOT
  }

  depends_on = [
    null_resource.longhorn_proxy_secrets,
    null_resource.alloy_proxy_secrets,
    null_resource.traefik_proxy_secrets,
    null_resource.radar_proxy_secrets,
    null_resource.argo_cd_secrets,
    null_resource.grafana_secrets,
  ]
}
