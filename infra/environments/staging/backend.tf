terraform {
  # Key set by bootstrap (infra/<env>/terraform.tfstate): the CI roles may
  # only lock state under infra/.
  backend "s3" {
    bucket       = "tfstate-bookshelf-794457362166-us-east-2-an"
    key          = "infra/stg/terraform.tfstate"
    region       = "us-east-2"
    use_lockfile = true
  }
}
