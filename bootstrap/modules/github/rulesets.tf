# ---------------------------------------------------------------------------
# Rulesets: who can move the refs that deploy
#
# The environment's deployment policy decides WHICH refs may deploy; these
# rulesets decide WHO can move those refs:
#   branches  only through a pull request (no direct push, force push or delete)
#   tags      only `tag_creators` can create, move or delete them
# ---------------------------------------------------------------------------

locals {
  # Base repository role IDs used by rulesets bypass actors
  repository_role_ids = {
    maintain = 2
    write    = 4
    admin    = 5
  }

  branch_environments = { for env, cfg in var.environment : env => cfg if length(cfg.branches) > 0 }
  tag_environments    = { for env, cfg in var.environment : env => cfg if length(cfg.tags) > 0 }
}

resource "github_repository_ruleset" "branch" {
  for_each = local.branch_environments

  name        = "deploy-${each.key}"
  repository  = data.github_repository.this.name
  target      = "branch"
  enforcement = "active"

  conditions {
    ref_name {
      include = [for b in each.value.branches : "refs/heads/${b}"]
      exclude = []
    }
  }

  rules {
    deletion         = true
    non_fast_forward = true

    pull_request {
      required_approving_review_count   = each.value.required_approvals
      dismiss_stale_reviews_on_push     = each.value.required_approvals > 0
      require_last_push_approval        = each.value.required_approvals > 0
      required_review_thread_resolution = false
    }

    dynamic "required_status_checks" {
      for_each = length(each.value.required_checks) > 0 ? [1] : []
      content {
        strict_required_status_checks_policy = true

        dynamic "required_check" {
          for_each = each.value.required_checks
          content {
            context = required_check.value
          }
        }
      }
    }
  }
}

resource "github_repository_ruleset" "tag" {
  for_each = local.tag_environments

  name        = "deploy-${each.key}"
  repository  = data.github_repository.this.name
  target      = "tag"
  enforcement = "active"

  conditions {
    ref_name {
      include = [for t in each.value.tags : "refs/tags/${t}"]
      exclude = []
    }
  }

  rules {
    creation = true
    update   = true
    deletion = true
  }

  dynamic "bypass_actors" {
    for_each = toset(var.tag_creators)
    content {
      actor_id    = local.repository_role_ids[bypass_actors.value]
      actor_type  = "RepositoryRole"
      bypass_mode = "always"
    }
  }
}
