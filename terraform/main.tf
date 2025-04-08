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
  minio_access_label     = var.minio_access_label
  postgres_access_label  = var.postgres_access_label
  everest_ns             = var.everest_ns
  minio_ns               = var.minio_ns
  oidc_access_label      = var.oidc_access_label
  positron_ns            = var.positron_ns
  cert_issuer_prod       = var.cert_issuer_prod
}

module "network" {
  source = "./network"

  ingress_class       = var.ingress_class
  email               = var.email
  cert_issuer_prod    = var.cert_issuer_prod
  cert_issuer_staging = var.cert_issuer_staging
  cert_ns             = var.cert_ns
}

module "secrets" {
  source = "./secrets"

  storage_class          = var.storage_class
  cluster_secret_store   = var.cluster_secret_store
  secret_store_label     = var.secret_store_label
  cluster_ca_cert_label  = var.cluster_ca_cert_label
  positron_ns            = var.positron_ns
  oidc_access_label      = var.oidc_access_label
  cloudflare_ca_cert_var = var.cloudflare_ca_cert_var
  cloudflare_cert_label  = var.cloudflare_cert_label
  cloudflare_cert_var    = var.cloudflare_cert_var
  ingress_class          = var.ingress_class

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
  minio_access_label     = var.minio_access_label
  postgres_access_label  = var.postgres_access_label
  everest_ns             = var.everest_ns
  minio_ns               = var.minio_ns
  cluster_ca_cert_label  = var.cluster_ca_cert_label
  oidc_access_label      = var.oidc_access_label
  positron_ns            = var.positron_ns
  storage_class          = var.storage_class
  cluster_secret_store   = var.cluster_secret_store
  cert_issuer_prod       = var.cert_issuer_prod
  cert_issuer_staging    = var.cert_issuer_staging
  cert_ns                = var.cert_ns
}
