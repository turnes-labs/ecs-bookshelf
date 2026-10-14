# ---------------------------------------------------------------------------
# OIDC subject template
#
# Adds the workflow file to every token's `sub`, so AWS can trust a role to one
# workflow and not to every job that runs in an environment:
#   <repo>:environment:<env>:job_workflow_ref:<org>/<repo>/.github/workflows/<file>@<ref>
#   <repo>:pull_request:job_workflow_ref:<org>/<repo>/.github/workflows/<file>@<ref>
# For immutable-subject repositories GitHub keeps the owner and repo IDs in <repo>.
# The trust policies in modules/aws/templates/*-trust.json.tpl expect this format.
# ---------------------------------------------------------------------------

resource "github_actions_repository_oidc_subject_claim_customization_template" "this" {
  repository         = data.github_repository.this.name
  use_default        = false
  include_claim_keys = ["repo", "context", "job_workflow_ref"]
}
