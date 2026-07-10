terraform {
  required_version = "~> 1.15"

  required_providers {
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "~> 1.0"
    }
  }
}
