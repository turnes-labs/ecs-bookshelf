# ---------------------------------------------------------------------------
# GitHub Actions: pull request, one role for every environment
# ---------------------------------------------------------------------------

locals {
  plan_tpl_vars = {
    state_bucket        = aws_s3_bucket.this.id
    oidc_subject_prefix = var.oidc_subject_prefix
    oidc_provider_arn   = local.oidc_provider_arn
  }

  # templates/plan-<concern>.json.tpl, one managed policy each
  plan_concerns = toset(["state"])
}

resource "aws_iam_role" "plan" {
  name               = "${var.prefix}-plan"
  assume_role_policy = templatefile("${path.module}/templates/plan-trust.json.tpl", local.plan_tpl_vars)
}

resource "aws_iam_role_policy_attachment" "plan_readonly" {
  role       = aws_iam_role.plan.name
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}

resource "aws_iam_policy" "plan" {
  for_each = local.plan_concerns

  name   = "${var.prefix}-plan-${each.key}"
  policy = templatefile("${path.module}/templates/plan-${each.key}.json.tpl", local.plan_tpl_vars)
}

resource "aws_iam_role_policy_attachment" "plan" {
  for_each = local.plan_concerns

  role       = aws_iam_role.plan.name
  policy_arn = aws_iam_policy.plan[each.key].arn
}
