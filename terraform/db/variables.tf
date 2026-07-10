variable "cert_issuer_prod" {
  description = "The certificate issuer for production"
  type        = string
}

variable "cluster_secret_store" {
  description = "The name of the ClusterSecretStore to use for external secrets"
  type        = string
}

variable "garage_ns" {
  description = "The namespace where MinIO will be deployed"
  type        = string
  default     = "garage"
}

variable "storage_class" {
  description = "The storage class to use for persistent volumes"
  type        = string
}

variable "cloudflare_ca_cert_var" {
  description = "The variable name for the Cloudflare CA certificate"
  type        = string
}

variable "cloudflare_cert_var" {
  description = "The variable name for the Cloudflare certificate"
  type        = string
}

variable "ingress_class" {
  description = "The ingress class to use for ingress resources"
  type        = string
}

variable "pg_ns" {
  description = "The namespace where PostgreSQL will be deployed"
  type        = string
  default     = "postgres"
}

variable "secrets_ns" {
  description = "The namespace where secrets will be stored"
  type        = string
}

variable "smtp_password" {
  description = "The password for the SMTP server"
  type        = string
  sensitive   = true
}

variable "smtp_username" {
  description = "The username for the SMTP server"
  type        = string
}

variable "apod_api_key" {
  description = "The API key for the Astronomy Picture of the Day API"
  type        = string
  sensitive   = true
}

variable "discord_token" {
  description = "The token for the Discord bot used by the auto-clean bot"
  type        = string
  sensitive   = true
}

variable "discord_alert_webhook" {
  description = "The webhook URL for sending alerts to Discord"
  type        = string
  sensitive   = true
}
