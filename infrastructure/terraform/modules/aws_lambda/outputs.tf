output "lambda_function_arn" {
  description = "ARN of the Lambda function"
  value       = module.lambda_function.lambda_function_arn
}

output "lambda_function_name" {
  description = "Name of the Lambda function"
  value       = module.lambda_function.lambda_function_name
}

output "lambda_function_qualified_arn" {
  description = "Qualified ARN of the Lambda function (includes version)"
  value       = module.lambda_function.lambda_function_qualified_arn
}

output "lambda_function_invoke_arn" {
  description = "Invoke ARN of the Lambda function for API Gateway integration"
  value       = module.lambda_function.lambda_function_invoke_arn
}

output "lambda_cloudwatch_log_group_name" {
  description = "Name of the CloudWatch Log Group for the Lambda function"
  value       = module.lambda_function.lambda_cloudwatch_log_group_name
}

output "lambda_cloudwatch_log_group_arn" {
  description = "ARN of the CloudWatch Log Group for the Lambda function"
  value       = module.lambda_function.lambda_cloudwatch_log_group_arn
}

output "lambda_role_arn" {
  description = "ARN of the IAM role used by the Lambda function"
  value       = var.lambda_role
}
