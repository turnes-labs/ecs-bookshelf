# ---------------------------------------------------------------------------
# GitHub OIDC provider
#
# An account can have only one provider per URL. If another project already
# created it, set create_oidc_provider = false to use that one instead: this
# state then never owns it, so destroying bootstrap can't break other repos.
# ---------------------------------------------------------------------------

resource "aws_iam_openid_connect_provider" "github" {
  count = var.create_oidc_provider ? 1 : 0

  # No thumbprint_list: AWS validates GitHub's certificate against its own CA store
  url            = "https://token.actions.githubusercontent.com"
  client_id_list = ["sts.amazonaws.com"]
}

data "aws_iam_openid_connect_provider" "github" {
  count = var.create_oidc_provider ? 0 : 1

  url = "https://token.actions.githubusercontent.com"
}

locals {
  oidc_provider_arn = one(concat(
    aws_iam_openid_connect_provider.github[*].arn,
    data.aws_iam_openid_connect_provider.github[*].arn,
  ))
}
