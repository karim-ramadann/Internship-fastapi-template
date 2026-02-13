# SQS outputs
output "sqs_queue_arn" {
  description = "ARN of the SQS queue"
  value       = var.create_sqs ? module.sqs[0].queue_arn : null
}

output "sqs_queue_url" {
  description = "URL of the SQS queue"
  value       = var.create_sqs ? module.sqs[0].queue_url : null
}

output "sqs_queue_name" {
  description = "Name of the SQS queue"
  value       = var.create_sqs ? module.sqs[0].queue_name : null
}

output "sqs_dlq_arn" {
  description = "ARN of the dead-letter queue"
  value       = var.create_sqs && var.create_dlq ? module.sqs_dlq[0].queue_arn : null
}

output "sqs_dlq_url" {
  description = "URL of the dead-letter queue"
  value       = var.create_sqs && var.create_dlq ? module.sqs_dlq[0].queue_url : null
}

# SNS outputs
output "sns_topic_arn" {
  description = "ARN of the SNS topic"
  value       = var.create_sns ? module.sns[0].topic_arn : null
}

output "sns_topic_name" {
  description = "Name of the SNS topic"
  value       = var.create_sns ? module.sns[0].topic_name : null
}
