provider "aws" {
  region = var.region

  # The deploy roles only create and manage resources whose Environment tag
  # matches their environment, so every resource must carry it.
  default_tags {
    tags = {
      Environment = var.environment
      ManagedBy   = "Terraform"
      Project     = "Book-ecs"
      Service     = "book"
    }
  }
}
