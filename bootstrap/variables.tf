variable "prefix" {
  type    = string
  default = "bookshelf"
}

variable "region" {
  type = string
}

variable "bucket_name" {
  type = string
}

variable "github_org" {
  description = "github organization or repo owner(user)"
  type        = string
}

variable "github_repo" {
  type = string
}

variable "create_oidc_provider" {
  description = "Create the GitHub OIDC provider. Set to false if the account already has one"
  type        = bool
  default     = true
}

variable "environment" {
  description = <<-EOT
    One entry per deployment environment. Each one gets its own IAM role (trusted
    only on the matching GitHub environment), GitHub environment, deployment
    rules, Actions variables and a ruleset protecting the refs that deploy it.
      branches            branches that deploy here on merge; each gets a ruleset
                          that only accepts changes through pull requests
      tags                tag patterns that deploy here; only `tag_creators` can
                          create, move or delete them
      required_approvals  PR approvals needed to merge into `branches`
      required_checks     status checks (job names) that must pass before merging
      reviewers           GitHub usernames that must approve each deployment
      wait_timer          minutes to wait before a deployment starts
  EOT
  type = map(object({
    branches           = optional(list(string), [])
    tags               = optional(list(string), [])
    required_approvals = optional(number, 0)
    required_checks    = optional(list(string), [])
    reviewers          = optional(list(string), [])
    wait_timer         = optional(number, 0)
  }))
  default = {
    # Merge a PR into dev: anyone with write access who can merge
    dev = {
      branches = ["dev"]
    }
    # Merge a PR into main: needs an approval from someone other than the author
    stg = {
      branches           = ["main"]
      required_approvals = 1
    }
    # Push a v* tag: only `tag_creators`
    prod = {
      tags = ["v*"]
    }
  }

  # Exactly one kind of ref per environment. Without any, the GitHub environment
  # would accept every ref, so any branch could assume its AWS role. With both,
  # the two deploy-<env> rulesets would collide.
  validation {
    condition     = alltrue([for cfg in var.environment : (length(cfg.branches) > 0) != (length(cfg.tags) > 0)])
    error_message = "Each environment must set either branches or tags (not both, not neither)."
  }

  # Each deploy role manages task roles named <prefix>-<env>-*. An environment
  # called "deploy" would match <prefix>-deploy-*, i.e. every other deploy role.
  validation {
    condition     = !contains(keys(var.environment), "deploy")
    error_message = "An environment can't be named \"deploy\": its task roles would overlap the <prefix>-deploy-<env> CI roles."
  }
}

variable "tag_creators" {
  description = "Repository roles allowed to create, move or delete deploy tags"
  type        = list(string)
  default     = ["maintain", "admin"]

  validation {
    condition     = alltrue([for r in var.tag_creators : contains(["maintain", "write", "admin"], r)])
    error_message = "tag_creators must be base repository roles: maintain, write or admin."
  }
}
