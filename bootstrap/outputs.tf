output "state_bucket" {
  description = "Terraform state bucket name"
  value       = module.aws.state_bucket
}

output "plan_role_arn" {
  description = "Role assumed by pull request (plan) jobs"
  value       = module.aws.plan_role_arn
}

output "deploy_role_arns" {
  description = "Deploy role ARN per environment"
  value       = module.aws.deploy_role_arns
}

output "state_keys" {
  description = "State object key per environment"
  value       = module.aws.state_keys
}
