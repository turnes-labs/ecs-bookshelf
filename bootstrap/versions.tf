terraform {
  required_version = ">= 1.16.0, < 2.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    github = {
      source  = "integrations/github"
      version = "~> 6.6"
    }
  }

  # backend "s3" {
  #   bucket = "tfstate-bookshelf-794457362166-us-east-2-an"
  #   key          = "bootstrap/terraform.tfstate"
  #   region       = "us-east-2"
  #   use_lockfile = true
  # }
}
