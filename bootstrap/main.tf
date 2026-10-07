provider "aws" {
  region = var.region

  default_tags {
    tags = {
      Project    = var.prefix
      ManagedBy  = "terraform"
      Repository = "${var.github_org}/${var.github_repo}"
      Stack      = "bootstrap"
    }
  }
}

provider "github" {
  owner = var.github_org
}

# The `sub` prefix GitHub uses in this repo's OIDC tokens. Repositories created
# or renamed after 2026-07-15 use immutable IDs (repo:<org>@<id>/<repo>@<id>),
# older ones use repo:<org>/<repo>, and a custom template changes it again, so
# read it instead of building it.
# https://docs.github.com/en/actions/reference/security/oidc#immutable-subject-claims
data "github_rest_api" "oidc_subject" {
  endpoint = "repos/${var.github_org}/${var.github_repo}/actions/oidc/customization/sub"
}

module "aws" {
  source       = "./modules/aws"
  prefix       = var.prefix
  bucket_name  = var.bucket_name
  environments = keys(var.environment)

  oidc_subject_prefix  = jsondecode(data.github_rest_api.oidc_subject.body).sub_claim_prefix
  create_oidc_provider = var.create_oidc_provider
}

module "github" {
  source           = "./modules/github"
  github_org       = var.github_org
  github_repo      = var.github_repo
  region           = var.region
  environment      = var.environment
  tag_creators     = var.tag_creators
  state_bucket     = module.aws.state_bucket
  state_keys       = module.aws.state_keys
  plan_role_arn    = module.aws.plan_role_arn
  deploy_role_arns = module.aws.deploy_role_arns
}
