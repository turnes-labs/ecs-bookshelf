variable "environment" {
  description = "Environment name, as defined in bootstrap (dev, stg, prod)"
  type        = string

  validation {
    condition     = contains(["dev", "stg", "prod"], var.environment)
    error_message = "Environment must be one of: dev, stg, prod. Got: '${var.environment}'."
  }
}

variable "region" {
  description = "AWS region"
  type        = string
}

variable "vpc_cidr" {
  description = "VPC CIDR block (/16), unique per environment so VPCs can be peered later"
  type        = string
}

variable "availability_zones" {
  description = "Availability zones for the public and private subnets"
  type        = list(string)
}
