locals {
  name_prefix = "bookshelf-${var.environment}"
}

module "network" {
  source = "../../modules/aws-network"

  name_prefix        = local.name_prefix
  vpc_cidr           = var.vpc_cidr
  availability_zones = var.availability_zones
}

# module "network" {
#   source = "../../modules/aws-ecs"

#   name_prefix        = local.name_prefix
#   vpc_cidr           = var.vpc_cidr
#   availability_zones = var.availability_zones
# }
