# ---------------------------------------------------------------------------
# Project
# ---------------------------------------------------------------------------

variable "prefix" {
  description = "Name prefix for every resource: roles <prefix>-deploy-<env>, <prefix>-plan, and the <prefix>-<env>-* resources the deploy roles manage"
  type        = string
}

variable "environments" {
  description = "Deployment environment names; one deploy role, policy set and state key each"
  type        = set(string)
}

variable "oidc_subject_prefix" {
  description = "Prefix of the `sub` claim in this repository's GitHub OIDC tokens, e.g. repo:<org>@<id>/<repo>@<id>"
  type        = string

  validation {
    condition     = startswith(var.oidc_subject_prefix, "repo:")
    error_message = "oidc_subject_prefix must start with \"repo:\"."
  }
}

variable "create_oidc_provider" {
  description = "Create the GitHub OIDC provider. Set to false if the account already has one"
  type        = bool
  default     = true
}

# ---------------------------------------------------------------------------
# S3 Backend
# ---------------------------------------------------------------------------

variable "bucket_name" {
  description = "State bucket name; the account ID and region are appended (<name>-<account>-<region>-an)"
  type        = string
}

variable "backup_transition_days" {
  description = "Number of days before transitioning backups to a cheaper storage tier."
  type        = number
  default     = 30

  validation {
    condition     = var.backup_transition_days >= 30
    error_message = "S3 moves objects to STANDARD_IA only after 30 days or more."
  }
}

variable "backup_expiration_days" {
  description = "Number of days before permanently deleting noncurrent backups."
  type        = number
  default     = 90

  validation {
    condition     = var.backup_expiration_days > var.backup_transition_days
    error_message = "Expiration days must be greater than transition days."
  }

  validation {
    condition     = var.backup_expiration_days >= 30
    error_message = "it's not recomended to delete before 30 days"
  }
}

variable "kms_master_key_id" {
  description = "KMS key for the state bucket's SSE-KMS encryption. null uses the AWS-managed aws/s3 key"
  type        = string
  default     = null
}
