output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.this.id
}

output "public_subnet_ids" {
  description = "Public subnet IDs, one per availability zone"
  value       = [for s in aws_subnet.public : s.id]
}

output "private_subnet_ids" {
  description = "Private subnet IDs, one per availability zone"
  value       = [for s in aws_subnet.private : s.id]
}

output "internal_subnet_id" {
  description = "Internal subnet ID (no route out of the VPC)"
  value       = aws_subnet.internal.id
}

output "azs" {
  description = "list of azs"
  value       = local.azs
}
