output "eventbridge_bus_arn" {
  description = "The ARN of the EventBridge bus"
  value       = module.eventbridge.eventbridge_bus_arn
}

output "eventbridge_bus_name" {
  description = "The name of the EventBridge bus"
  value       = module.eventbridge.eventbridge_bus_name
}

output "eventbridge_rules" {
  description = "Map of EventBridge rules created and their attributes"
  value       = module.eventbridge.eventbridge_rules
}

output "eventbridge_targets" {
  description = "Map of EventBridge targets created and their attributes"
  value       = module.eventbridge.eventbridge_targets
}

output "eventbridge_archives" {
  description = "Map of EventBridge archives created and their attributes"
  value       = module.eventbridge.eventbridge_archives
}

output "eventbridge_permissions" {
  description = "Map of EventBridge permissions created and their attributes"
  value       = module.eventbridge.eventbridge_permissions
}

output "eventbridge_connections" {
  description = "Map of EventBridge connections created and their attributes"
  value       = module.eventbridge.eventbridge_connections
}

output "eventbridge_api_destinations" {
  description = "Map of EventBridge API destinations created and their attributes"
  value       = module.eventbridge.eventbridge_api_destinations
}

output "eventbridge_schedule_groups" {
  description = "Map of EventBridge schedule groups created and their attributes"
  value       = module.eventbridge.eventbridge_schedule_groups
}

output "eventbridge_schedules" {
  description = "Map of EventBridge schedules created and their attributes"
  value       = module.eventbridge.eventbridge_schedules
}

output "eventbridge_pipes" {
  description = "Map of EventBridge pipes created and their attributes"
  value       = module.eventbridge.eventbridge_pipes
}

output "eventbridge_role_arn" {
  description = "The ARN of the IAM role created for EventBridge"
  value       = module.eventbridge.eventbridge_role_arn
}

output "eventbridge_role_name" {
  description = "The name of the IAM role created for EventBridge"
  value       = module.eventbridge.eventbridge_role_name
}

output "eventbridge_pipe_role_arn" {
  description = "The ARN of the IAM role created for EventBridge Pipes"
  value       = module.eventbridge.eventbridge_pipe_role_arn
}

output "eventbridge_pipe_role_name" {
  description = "The name of the IAM role created for EventBridge Pipes"
  value       = module.eventbridge.eventbridge_pipe_role_name
}
