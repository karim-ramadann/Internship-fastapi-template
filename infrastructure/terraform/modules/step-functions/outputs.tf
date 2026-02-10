output "state_machine_arn" {
  description = "ARN of the Step Functions state machine"
  value       = module.step_function.state_machine_arn
}

output "state_machine_name" {
  description = "Name of the Step Functions state machine"
  value       = module.step_function.state_machine_name
}

output "state_machine_id" {
  description = "ID of the Step Functions state machine"
  value       = module.step_function.state_machine_id
}

output "state_machine_creation_date" {
  description = "Creation date of the Step Functions state machine"
  value       = module.step_function.state_machine_creation_date
}

output "state_machine_status" {
  description = "Current status of the Step Functions state machine"
  value       = module.step_function.state_machine_status
}

output "cloudwatch_log_group_name" {
  description = "Name of the CloudWatch Log Group for Step Functions execution logs"
  value       = aws_cloudwatch_log_group.step_functions.name
}

output "cloudwatch_log_group_arn" {
  description = "ARN of the CloudWatch Log Group for Step Functions execution logs"
  value       = aws_cloudwatch_log_group.step_functions.arn
}

output "role_arn" {
  description = "ARN of the IAM role used by the Step Functions state machine"
  value       = var.role_arn
}
