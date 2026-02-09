output "backend_log_group_name" {
  description = "Name of the backend CloudWatch log group"
  value       = aws_cloudwatch_log_group.backend.name
}

output "frontend_log_group_name" {
  description = "Name of the frontend CloudWatch log group"
  value       = aws_cloudwatch_log_group.frontend.name
}

output "adminer_log_group_name" {
  description = "Name of the adminer CloudWatch log group"
  value       = aws_cloudwatch_log_group.adminer.name
}

output "prestart_log_group_name" {
  description = "Name of the prestart CloudWatch log group"
  value       = aws_cloudwatch_log_group.prestart.name
}

output "sns_topic_arn" {
  description = "ARN of the SNS topic for alarms (if enabled)"
  value       = var.enable_alarms ? aws_sns_topic.alarms[0].arn : null
}
