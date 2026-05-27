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
    module.longhorn,
    module.alloy,
    module.treafik,
    module.radar,
    module.argocd,
    module.grafana,
  ]
}
