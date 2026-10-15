variable "name_prefix" {
  description = "Prefix for resource names, <prefix>-<env> (e.g. bookshelf-dev)"
  type        = string
}

variable "vpc_cidr" {
  description = "VPC CIDR block; must be a /16 so each subnet gets a /24"
  type        = string

  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "vpc_cidr must be a valid"
  }
}

variable "availability_zones" {
  description = "Availability zones for the public and private subnets, one subnet of each per AZ"
  type        = list(string)

  validation {
    condition     = length(var.availability_zones) >= 2
    error_message = "Set at least two availability zones."
  }
}
