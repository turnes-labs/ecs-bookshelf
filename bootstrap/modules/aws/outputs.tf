output "state_bucket" {
  value = aws_s3_bucket.this.id
}

output "plan_role_arn" {
  value = aws_iam_role.plan.arn
}

output "deploy_role_arns" {
  value = { for env, role in aws_iam_role.deploy : env => role.arn }
}

# Same key layout the deploy and plan policies grant (infra/<env>/*)
output "state_keys" {
  value = { for env in keys(var.environment) : env => "infra/${env}/terraform.tfstate" }
}
