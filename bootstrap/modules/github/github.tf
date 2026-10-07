# ---------------------------------------------------------------------------
# GitHub repository: environments, deployment rules and Actions variables
# ---------------------------------------------------------------------------

locals {
  repo_full_name = "${var.github_org}/${var.github_repo}"
}

data "github_repository" "this" {
  full_name = local.repo_full_name
}

data "github_user" "reviewer" {
  for_each = toset(flatten([for cfg in var.environment : cfg.reviewers]))

  username = each.value
}

resource "github_repository_environment" "this" {
  for_each = var.environment

  repository          = data.github_repository.this.name
  environment         = each.key
  wait_timer          = each.value.wait_timer
  can_admins_bypass   = false
  prevent_self_review = false

  dynamic "reviewers" {
    for_each = length(each.value.reviewers) > 0 ? [1] : []
    content {
      users = [for u in each.value.reviewers : data.github_user.reviewer[u].id]
    }
  }

  # Only the refs in github_repository_environment_deployment_policy may deploy.
  # Without this block any ref could run a job here and assume the AWS role.
  deployment_branch_policy {
    protected_branches     = false
    custom_branch_policies = true
  }
}

locals {
  deployment_policies = merge([
    for env, cfg in var.environment : merge(
      { for b in cfg.branches : "${env}/branch/${b}" => { env = env, branch = b, tag = null } },
      { for t in cfg.tags : "${env}/tag/${t}" => { env = env, branch = null, tag = t } },
    )
  ]...)
}

resource "github_repository_environment_deployment_policy" "this" {
  for_each = local.deployment_policies

  repository     = data.github_repository.this.name
  environment    = github_repository_environment.this[each.value.env].environment
  branch_pattern = each.value.branch
  tag_pattern    = each.value.tag
}

# Repository-level variables: shared by every workflow, including PR plans
resource "github_actions_variable" "repo" {
  for_each = {
    AWS_REGION        = var.region
    AWS_PLAN_ROLE_ARN = var.plan_role_arn
    TF_STATE_BUCKET   = var.state_bucket
    ENVIRONMENTS      = jsonencode(keys(var.environment))
  }

  repository    = data.github_repository.this.name
  variable_name = each.key
  value         = each.value
}

# Environment-level variables: resolved by jobs with `environment: <name>`
locals {
  environment_variables = merge([
    for env in keys(var.environment) : {
      "${env}/AWS_ROLE_ARN" = { env = env, name = "AWS_ROLE_ARN", value = var.deploy_role_arns[env] }
      "${env}/TF_STATE_KEY" = { env = env, name = "TF_STATE_KEY", value = var.state_keys[env] }
    }
  ]...)
}

resource "github_actions_environment_variable" "this" {
  for_each = local.environment_variables

  repository    = data.github_repository.this.name
  environment   = github_repository_environment.this[each.value.env].environment
  variable_name = each.value.name
  value         = each.value.value
}
