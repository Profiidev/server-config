terraform {
  required_version = "~> 1.11"

  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.0"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "~> 1.0"
    }
    external = {
      source  = "hashicorp/external"
      version = "~> 2.0"
    }
  }

  backend "kubernetes" {
    namespace     = "kube-system"
    secret_suffix = "network"
  }
}
