# ---------------------------------------------------------------------------
# GitHub Actions: deploy, one role per environment
# ---------------------------------------------------------------------------

locals {
  # One set of template variables per environment, shared by every template:
  # deploy-trust, deploy-{network,compute,data,iam} and task-boundary.
  tpl_vars = {
    for env in var.environments : env => {
      environment         = env
      name_prefix         = "${var.prefix}-${env}"
      region              = local.region
      account_id          = local.account_id
      state_bucket        = aws_s3_bucket.this.id
      oidc_subject_prefix = var.oidc_subject_prefix
      oidc_provider_arn   = local.oidc_provider_arn
      boundary_arn        = "arn:aws:iam::${local.account_id}:policy/${var.prefix}-${env}-task-boundary"
    }
  }

  # templates/deploy-<concern>.json.tpl, one managed policy each
  deploy_concerns = ["network", "compute", "data", "iam"]

  deploy_policies = {
    for pair in setproduct(keys(local.tpl_vars), local.deploy_concerns) :
    "${pair[0]}/${pair[1]}" => { env = pair[0], concern = pair[1] }
  }
}

resource "aws_iam_role" "deploy" {
  for_each = local.tpl_vars

  name               = "${var.prefix}-deploy-${each.key}"
  assume_role_policy = templatefile("${path.module}/templates/deploy-trust.json.tpl", each.value)
}

resource "aws_iam_policy" "deploy" {
  for_each = local.deploy_policies

  name   = "${var.prefix}-deploy-${each.value.env}-${each.value.concern}"
  policy = templatefile("${path.module}/templates/deploy-${each.value.concern}.json.tpl", local.tpl_vars[each.value.env])
}

resource "aws_iam_role_policy_attachment" "deploy" {
  for_each = local.deploy_policies

  role       = aws_iam_role.deploy[each.value.env].name
  policy_arn = aws_iam_policy.deploy[each.key].arn
}

# Ceiling for the task roles the deploy role creates (see deploy-iam.json.tpl)
resource "aws_iam_policy" "task_boundary" {
  for_each = local.tpl_vars

  name   = "${var.prefix}-${each.key}-task-boundary"
  policy = templatefile("${path.module}/templates/task-boundary.json.tpl", each.value)
}
