output "state_bucket" {
  value = module.aws.state_bucket
}

output "plan_role_arn" {
  value = module.aws.plan_role_arn
}

output "deploy_role_arns" {
  value = module.aws.deploy_role_arns
}

output "state_keys" {
  value = module.aws.state_keys
}
