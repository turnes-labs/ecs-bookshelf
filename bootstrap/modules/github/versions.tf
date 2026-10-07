terraform {
  # Minimums only: the root module pins exact ranges
  required_version = ">= 1.16.0"

  required_providers {
    github = {
      source  = "integrations/github"
      version = ">= 6.6"
    }
  }
}
