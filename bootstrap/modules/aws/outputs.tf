output "state_bucket" {
  description = "Terraform state bucket name"
  value       = aws_s3_bucket.this.id
}

output "plan_role_arn" {
  description = "Role assumed by pull request (plan) jobs"
  value       = aws_iam_role.plan.arn
}

output "deploy_role_arns" {
  description = "Deploy role ARN per environment"
  value       = { for env, role in aws_iam_role.deploy : env => role.arn }
}

# Same key layout the deploy and plan policies grant (infra/<env>/*)
output "state_keys" {
  description = "State object key per environment"
  value       = { for env in var.environments : env => "infra/${env}/terraform.tfstate" }
}
