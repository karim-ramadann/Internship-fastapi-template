output "alb_security_group_id" {
  description = "ID of the ALB security group"
  value       = module.alb_security_group.security_group_id
}

output "rds_security_group_id" {
  description = "ID of the RDS security group"
  value       = module.rds_security_group.security_group_id
}

# Lambda & Step Functions Outputs
output "lambda_execution_role_arn" {
  description = "ARN of Lambda execution IAM role"
  value       = aws_iam_role.lambda_execution_role.arn
}

output "lambda_security_group_id" {
  description = "ID of Lambda security group"
  value       = module.lambda_security_group.security_group_id
}

output "step_functions_execution_role_arn" {
  description = "ARN of Step Functions execution IAM role"
  value       = aws_iam_role.step_functions_execution_role.arn
}
