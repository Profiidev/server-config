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
    local = {
      source  = "hashicorp/local"
      version = "~> 2.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.0"
    }
    template = {
      source  = "hashicorp/template"
      version = "~> 2.0"
    }
  }
}

module "storage" {
  source = "./storage"

  storage_class          = var.storage_class
  ingress_class          = var.ingress_class
  cloudflare_ca_cert_var = var.cloudflare_ca_cert_var
  cloudflare_cert_label  = var.cloudflare_cert_label
  cloudflare_cert_var    = var.cloudflare_cert_var
  secret_store_label     = var.secret_store_label
  cluster_secret_store   = var.cluster_secret_store
}

module "network" {
  source = "./network"

  ingress_class = var.ingress_class
  email         = var.email
}

module "secrets" {
  source = "./secrets"

  storage_class        = var.storage_class
  cluster_secret_store = var.cluster_secret_store
  secret_store_label   = var.secret_store_label

  depends_on = [module.storage]
}

module "utils" {
  source = "./utils"

  cloudflare_ca_cert_var = var.cloudflare_ca_cert_var
  cloudflare_cert_label  = var.cloudflare_cert_label
  cloudflare_cert_var    = var.cloudflare_cert_var
  cluster_secret_store   = var.cluster_secret_store

  depends_on = [module.secrets]
}

module "tools" {
  source = "./tools"

  cloudflare_ca_cert_var = var.cloudflare_ca_cert_var
  cloudflare_cert_label  = var.cloudflare_cert_label
  cloudflare_cert_var    = var.cloudflare_cert_var
  ingress_class          = var.ingress_class
  secret_store_label     = var.secret_store_label
}
