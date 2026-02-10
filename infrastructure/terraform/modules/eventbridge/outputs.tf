output "eventbridge_bus_arn" {
  description = "ARN of the EventBridge event bus"
  value       = var.create_bus ? aws_cloudwatch_event_bus.this[0].arn : "arn:aws:events:${var.context.region}:*:event-bus/default"
}

output "eventbridge_bus_name" {
  description = "Name of the EventBridge event bus"
  value       = local.bus_name
}

output "eventbridge_rule_ids" {
  description = "Map of EventBridge rule IDs"
  value       = module.eventbridge.eventbridge_rule_ids
}

output "eventbridge_rule_arns" {
  description = "Map of EventBridge rule ARNs"
  value       = module.eventbridge.eventbridge_rule_arns
}
