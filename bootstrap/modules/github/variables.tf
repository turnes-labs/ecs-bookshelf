# ---------------------------------------------------------------------------
# Project
# ---------------------------------------------------------------------------

variable "github_org" {
  description = "github organization or repo owner(user)"
  type        = string
}

variable "github_repo" {
  type = string
}

variable "region" {
  type = string
}

variable "environment" {
  description = "Deployment environments; see the root module's `environment` variable"
  type = map(object({
    branches           = list(string)
    tags               = list(string)
    required_approvals = number
    required_checks    = list(string)
    reviewers          = list(string)
    wait_timer         = number
  }))
}

variable "tag_creators" {
  description = "Repository roles allowed to create, move or delete deploy tags"
  type        = list(string)
}

# ---------------------------------------------------------------------------
# From the aws module
# ---------------------------------------------------------------------------

variable "state_bucket" {
  description = "Terraform state bucket"
  type        = string
}

variable "state_keys" {
  description = "State object key per environment"
  type        = map(string)
}

variable "plan_role_arn" {
  description = "Role assumed by pull request (plan) jobs"
  type        = string
}

variable "deploy_role_arns" {
  description = "Deploy role per environment"
  type        = map(string)
}
