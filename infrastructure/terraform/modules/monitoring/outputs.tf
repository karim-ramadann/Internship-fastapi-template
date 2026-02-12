output "sns_topic_arn" {
  description = "ARN of the SNS topic for alarms (if enabled)"
  value       = var.enable_alarms ? aws_sns_topic.alarms[0].arn : null
}
