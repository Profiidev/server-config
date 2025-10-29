variable "storage_ns" {
  description = "The namespace for storage resources"
  type        = string
}

variable "secrets_ns" {
  description = "The namespace for secrets management resources"
  type        = string
}

variable "k8s_api" {
  description = "The Kubernetes API server address"
  type        = string
}

variable "cluster_secret_store" {
  description = "The name of the cluster secret store"
  type        = string
}

variable "cloudflare_ca_cert_var" {
  description = "The name of the Cloudflare CA certificate secret"
  type        = string
}

variable "cloudflare_cert_var" {
  description = "The name of the Cloudflare certificate secret"
  type        = string
}



variable "vault_svc" {
  description = "The name of the Vault service"
  type        = string
  default     = "vault"
}

variable "vault_cert_var" {
  description = "The name of the Vault TLS secret"
  type        = string
  default     = "vault-server-tls"
}

variable "vault_cert_prop" {
  description = "The property name for the Vault TLS certificate"
  type        = string
  default     = "vault"
}

variable "vault_csr" {
  description = "The name of the Vault CSR"
  type        = string
  default     = "vault-csr"
}

variable "vault_global_token" {
  description = "The name of the Vault global token secret"
  type        = string
  default     = "vault-global-token"
}

variable "vault_global_token_prop" {
  description = "The property name for the Vault global token"
  type        = string
  default     = "token"
}
