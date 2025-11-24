terraform {
  required_version = "~> 1.11"

  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
  }

  backend "kubernetes" {
    namespace     = "kube-system"
    secret_suffix = "docker"
  }
}

provider "docker" {
  host = "ssh://root@${var.k8s_api}"
  ssh_opts = [
    "-o", "StrictHostKeyChecking=no",
    "-o", "UserKnownHostsFile=/dev/null"
  ]
}
