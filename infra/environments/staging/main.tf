locals {
  # bookshelf-<env>: the deploy roles only manage load balancers, task roles,
  # etc. whose names start with this prefix (see bootstrap).
  name_prefix = "bookshelf-${var.environment}"
}

module "network" {
  source = "../../modules/aws-network"

  name_prefix        = local.name_prefix
  vpc_cidr           = var.vpc_cidr
  availability_zones = var.availability_zones
}
