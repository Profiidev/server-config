locals {
  positron_exec = "kubectl exec -n ${var.positron_ns} deploy/positron -- positron"
  vault_exec = "kubectl exec vault-0 -n ${var.secrets_ns} -- vault kv patch -mount=kv ${var.secret_path}"
  vault_token = jsondecode(file("${path.module}/../../storage/certs/global_token.json")).token
}

variable "enabled" {
  description = "Whether to create the app resources"
  type        = bool
  default     = true
}

variable "create" {
  description = "Whether to create the app secrets (set to false if the secrets are managed outside of Terraform)"
  type        = bool
  default     = true
}

variable "positron_ns" {
  description = "The namespace where Positron is deployed"
  type        = string
  default     = "positron"
}

variable "secrets_ns" {
  description = "The namespace where secrets are stored"
  type        = string
  default     = "secrets"
}

variable "secret_path" {
  description = "The path in Vault where the app secrets will be stored"
  type        = string
}

variable "oidc" {
  description = "The OIDC config"

  type = object({
    client_name = string
    redirect_uri = string
    scope = string
    admin_group = optional(string)
  })

  default = null
}

variable "client_id_var" {
  description = "The Vault variable name for the OIDC client ID"
  type        = string
  default = "client-id"
}

variable "client_secret_var" {
  description = "The Vault variable name for the OIDC client secret"
  type        = string
  default = "client-secret"
}

variable "cookie_secret" {
  description = "The secret key for signing cookies (if using the cookie module)"
  type        = bool
  default     = false
}

variable "cookie_secret_var" {
  description = "The Vault variable name for the cookie secret (if using the cookie module)"
  type        = string
  default     = "secret"
}

variable "additional_secrets" {
  description = "Additional secrets to store in Vault, as a map of variable name to value"
  type        = map(string)
  default     = {}
}

variable "extra_oidc_create" {
  description = "Additional commands to run after creating the OIDC client, as a list of strings (optional)"
  type        = string
  default     = ""
}

variable "extra_oidc_destroy" {
  description = "Additional commands to run before destroying the OIDC client, as a list of strings (optional)"
  type        = string
  default     = ""
}

variable "require_pkce" {
  description = "Whether to require PKCE for the OIDC client"
  type        = bool
  default     = false
}
