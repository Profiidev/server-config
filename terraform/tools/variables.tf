variable "portainer_ns" {
  description = "Portainer Namespace"
  type        = string
  default     = "portainer"
}

variable "vaultwarden_ns" {
  type    = string
  default = "vaultwarden"
}

variable "docker_ns" {
  type    = string
  default = "docker"
}

variable "proton_ns" {
  type    = string
  default = "proton"
}

variable "stalwart_ns" {
  type    = string
  default = "stalwart"
}

variable "metrics_ns" {
  type = string
}

variable "cert_issuer_staging" {
  type = string
}

variable "cert_issuer_prod" {
  type = string
}

variable "cloudflare_cert_label" {
  type = object({
    key   = string
    value = string
  })
}

variable "cloudflare_ca_cert_var" {
  type = string
}

variable "cloudflare_cert_var" {
  type = string
}

variable "secret_store_label" {
  type = object({
    key   = string
    value = string
  })
}

variable "ingress_class" {
  type = string
}

variable "cluster_secret_store" {
  type = string
}

variable "positron_ns" {
  type = string
}

variable "minio_access_label" {
  type = object({
    key   = string
    value = string
  })
}

variable "postgres_access_label" {
  type = object({
    key   = string
    value = string
  })
}

variable "everest_ns" {
  type = string
}

variable "minio_ns" {
  type = string
}

variable "cluster_ca_cert_label" {
  type = object({
    key   = string
    value = string
  })
}

variable "oidc_access_label" {
  type = object({
    key   = string
    value = string
  })
}

variable "storage_class" {
  type = string
}

variable "cert_ns" {
  type = string
}

variable "secrets_ns" {
  type = string
}

variable "storage_ns" {
  type = string
}

variable "everest_system_ns" {
  type = string
}

variable "ca_hash" {
  type = string
}

variable "nats_ns" {
  type = string
}

variable "nats_access_label" {
  type = object({
    key   = string
    value = string
  })
}

variable "coder_ns" {
  type    = string
  default = "coder"
}

variable "argo_ns" {
  type    = string
  default = "argo-system"
}

variable "charm_ns" {
  type    = string
  default = "charm"
}

variable "ghcr_profidev" {
  type = string
}

variable "ghcr_profidev_label" {
  type = object({
    key   = string
    value = string
  })
}

variable "auto_clean_bot_ns" {
  type    = string
  default = "auto-clean-bot"
}

variable "tailscale_ns" {
  type    = string
  default = "tailscale"
}

variable "higgs_ns" {
  type    = string
  default = "higgs"
}
