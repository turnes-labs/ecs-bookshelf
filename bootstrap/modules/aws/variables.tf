# ---------------------------------------------------------------------------
# Project
# ---------------------------------------------------------------------------

variable "prefix" {
  type    = string
  default = "bookshelf"
}

variable "environment" {
  type    = map(any)
  default = { dev = {}, stg = {}, prod = {} }
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
  type = string
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
  description = "AWS KMS master key ID used for the SSE-KMS encryption. "
  default     = null
}
