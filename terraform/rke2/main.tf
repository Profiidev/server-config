locals {
  local_file_path = "${path.root}/data"
  sudoers_file    = "/etc/sudoers.d/temp_nopasswd"
}

resource "null_resource" "initial-setup" {
  connection {
    type  = "ssh"
    agent = true
    user  = var.ssh_user
    host  = var.ssh_ip
  }
  provisioner "remote-exec" {
    inline = [<<-EOT
      #!/bin/bash
      set -x
      set -e
      # disable sudo password prompt for ssh user
      sudo -k && echo -e '${var.ssh_user_pw}\n${var.ssh_user} ALL=(ALL) NOPASSWD: ALL' | sudo -S tee ${local.sudoers_file} > /dev/null 2>&1
      
      # install dependencies
      sudo apt-get update && sudo apt-get upgrade -y
      sudo apt-get install -y curl iptables
    EOT
    ]
  }
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
  pod-security-admission-config-file = "/etc/rancher/rke2/config.yaml.d/pss-custom.yaml"
}

module "rke2-install" {
  depends_on = [module.download, module.config, null_resource.initial-setup]

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

resource "null_resource" "disable-password-less-sudo" {
  depends_on = [module.rke2-install]

  connection {
    type  = "ssh"
    agent = true
    user  = var.ssh_user
    host  = var.ssh_ip
  }
  provisioner "remote-exec" {
    inline = [<<-EOT
      set -x
      set -e
      # re-enable sudo password prompt for ssh user
      sudo rm -f ${local.sudoers_file}
    EOT
    ]
  }
}
