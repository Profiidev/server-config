locals {
  db_exec = "kubectl exec -n ${var.db_ns} postgres-postgresql-0 -c postgresql -- env PGPASSWORD='${var.db_password}' psql -U postgres"
  vault_exec = "kubectl exec vault-0 -n ${var.secrets_ns} -- vault kv patch -mount=kv ${var.secret_path}"
  s3_exec = "kubectl exec -n ${var.s3_ns} garage-0 -c garage -- /garage"
  s3_host = "http://garage.${var.s3_ns}.svc.cluster.local:3900"
  vault_token = jsondecode(file("${path.module}/../../storage/certs/global_token.json")).token
  db_url_base = "postgres://postgres:${var.db_password}@postgres-postgresql.${var.db_ns}.svc:5432"
}

variable "enabled" {
  description = "Whether to create the app resources"
  type        = bool
  default     = true
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

variable "db_name" {
  description = "The name of the database to create for the app (if using the db module)"
  type        = string
  default     = null
}

variable "db_url_var" {
  description = "The Vault variable name for the database connection URL (if using the db module)"
  type        = string
  default     = "DB_URL"
}

variable "db_password" {
  description = "The password for the database (if using the db module)"
  type        = string
  default     = "password"
}

variable "db_ns" {
  description = "The namespace where the database is deployed (if using the db module)"
  type        = string
  default     = "postgres"
}

variable "s3_ns" {
  description = "The namespace where the S3-compatible storage is deployed (if using the bucket module)"
  type        = string
  default     = "garage"
}

variable "s3_bucket" {
  description = "The name of the S3 bucket to create for the app (if using the bucket module)"
  type        = string
  default = null
}

variable "s3_access_key_var" {
  description = "The Vault variable name for the S3 access key (if using the bucket module)"
  type        = string
  default     = "S3_ACCESS_KEY"
}

variable "s3_secret_key_var" {
  description = "The Vault variable name for the S3 secret key (if using the bucket module)"
  type        = string
  default     = "S3_SECRET_KEY"
}

variable "s3_region_var" {
  description = "The Vault variable name for the S3 region (if using the bucket module)"
  type        = string
  default     = "S3_REGION"
}

variable "s3_bucket_var" {
  description = "The Vault variable name for the S3 bucket name (if using the bucket module)"
  type        = string
  default     = "S3_BUCKET"
}

variable "s3_host_var" {
  description = "The Vault variable name for the S3 host (if using the bucket module)"
  type        = string
  default     = "S3_HOST"
}

variable "s3_force_path_style_var" {
  description = "The Vault variable name for whether to force path style URLs for S3 (if using the bucket module)"
  type        = string
  default     = "S3_FORCE_PATH_STYLE"
}

variable "s3_force_path_style" {
  description = "Whether to force path style URLs for S3 (if using the bucket module)"
  type        = bool
  default     = true
}

variable "additional_secrets" {
  description = "Additional secrets to store in Vault, as a map of variable name to value"
  type        = map(string)
  default     = {}
}
