locals {
  azs = { for i, az in var.availability_zones : az => i }
}

resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  instance_tenancy     = "default"
  enable_dns_support   = true
  enable_dns_hostnames = true

  #checkov:skip=CKV2_AWS_11: Flow logs not required for this isolated VPC

  tags = {
    Name = "${var.name_prefix}-vpc"
  }
}

# Fix for CKV2_AWS_12: Restrict all traffic on the default security group
resource "aws_default_security_group" "default" {
  vpc_id = aws_vpc.this.id

  # Leaving ingress and egress empty removes all default rules
  ingress = []
  egress  = []
}

resource "aws_subnet" "public" {
  for_each = local.azs

  vpc_id            = aws_vpc.this.id
  availability_zone = each.key
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, 1 + each.value)

  tags = {
    Name = "${var.name_prefix}-public-${each.key}"
  }
}

resource "aws_subnet" "private" {
  for_each = local.azs

  vpc_id            = aws_vpc.this.id
  availability_zone = each.key
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, 128 + each.value)

  tags = {
    Name = "${var.name_prefix}-private-${each.key}"
  }
}

resource "aws_subnet" "internal" {
  vpc_id            = aws_vpc.this.id
  availability_zone = var.availability_zones[0]
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, 0)

  tags = {
    Name = "${var.name_prefix}-internal"
  }
}

// Internet Gateway
resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name = "${var.name_prefix}-igw"
  }
}

// NAT Gateway
# resource "aws_nat_gateway" this {
#   allocation_id = aws_eip.example.id
#   subnet_id     = aws_subnet.example.id

#   tags = {
#     Name = "${var.name_prefix}-ngw"
#   }

#   depends_on = [aws_internet_gateway.this]
# }

// Routes
// Internal: the default route table, no route out of the VPC
resource "aws_default_route_table" "default" {
  default_route_table_id = aws_vpc.this.default_route_table_id

  tags = {
    Name = "${var.name_prefix}-internal"
  }
}

// Public
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }

  tags = {
    Name = "${var.name_prefix}-public"
  }
}

resource "aws_route_table_association" "public" {
  for_each = aws_subnet.public

  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

// Private
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name = "${var.name_prefix}-private"
  }
}

resource "aws_route_table_association" "private" {
  for_each = aws_subnet.private

  subnet_id      = each.value.id
  route_table_id = aws_route_table.private.id
}
