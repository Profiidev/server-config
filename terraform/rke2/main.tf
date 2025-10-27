locals {
  local_file_path = "${path.root}/data"
}

module "download" {
  source  = "rancher/rke2-download/github"
  version = "1.0.0"
  path    = local.local_file_path
}


module "config" {
  depends_on = [module.download]

  source          = "rancher/rke2-config/local"
  version         = "1.0.0"
  local_file_path = local.local_file_path

  cni                 = ["calico"]
  profile             = "cis"
  etcd-expose-metrics = true
  kube-controller-manager-arg = [
    "bind-address=0.0.0.0"
  ]
  kube-scheduler-arg = [
    "bind-address=0.0.0.0"
  ]
  kube-proxy-arg = [
    "metrics-bind-address=0.0.0.0"
  ]
}

module "rke2-install" {
  depends_on = [module.download, module.config]

  source  = "rancher/rke2-install/null"
  version = "1.3.2"

  ssh_user            = var.ssh_user
  ssh_ip              = var.ssh_ip
  release             = "stable"
  local_file_path     = local.local_file_path
  identifier          = var.rke2_id
  remote_workspace    = "/home/${var.ssh_user}"
  retrieve_kubeconfig = true
  server_prep_script  = <<-EOT
    sudo cp -f /usr/local/share/rke2/rke2-cis-sysctl.conf /etc/sysctl.d/60-rke2-cis.conf
    sudo systemctl restart systemd-sysctl
    sudo sysctl -p /usr/local/share/rke2/rke2-cis-sysctl.conf
    sudo useradd -r -c "etcd user" -s /sbin/nologin -M etcd -U
  EOT
}
