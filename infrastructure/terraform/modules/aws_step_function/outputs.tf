output "state_machine_arn" {
  description = "The ARN of the Step Function"
  value       = module.step_function.state_machine_arn
}

output "state_machine_id" {
  description = "The ARN of the Step Function"
  value       = module.step_function.state_machine_id
}

output "state_machine_name" {
  description = "The name of the Step Function"
  value       = module.step_function.state_machine_name
}

output "state_machine_status" {
  description = "The current status of the Step Function"
  value       = module.step_function.state_machine_status
}

output "state_machine_creation_date" {
  description = "The date the Step Function was created"
  value       = module.step_function.state_machine_creation_date
}

output "state_machine_version_arn" {
  description = "The ARN of state machine version"
  value       = module.step_function.state_machine_version_arn
}

output "role_arn" {
  description = "The ARN of the IAM role created for the Step Function"
  value       = module.step_function.role_arn
}

output "role_name" {
  description = "The name of the IAM role created for the Step Function"
  value       = module.step_function.role_name
}

output "cloudwatch_log_group_arn" {
  description = "The ARN of the CloudWatch log group created for the Step Function"
  value       = module.step_function.cloudwatch_log_group_arn
}

output "cloudwatch_log_group_name" {
  description = "The name of the CloudWatch log group created for the Step Function"
  value       = module.step_function.cloudwatch_log_group_name
}
