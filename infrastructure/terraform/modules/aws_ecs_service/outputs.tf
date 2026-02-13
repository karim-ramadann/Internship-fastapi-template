output "service_id" {
  description = "ARN that identifies the service"
  value       = module.ecs_service.id
}

output "service_name" {
  description = "Name of the service"
  value       = module.ecs_service.name
}

output "task_definition_arn" {
  description = "Full ARN of the Task Definition (including both family and revision)"
  value       = module.ecs_service.task_definition_arn
}

output "task_definition_family" {
  description = "Family of the Task Definition"
  value       = module.ecs_service.task_definition_family
}

output "task_definition_revision" {
  description = "Revision of the task in a particular family"
  value       = module.ecs_service.task_definition_revision
}

output "security_group_id" {
  description = "ID of the security group created for the service"
  value       = module.ecs_service.security_group_id
}

output "security_group_arn" {
  description = "ARN of the security group created for the service"
  value       = module.ecs_service.security_group_arn
}

output "iam_role_arn" {
  description = "ARN of the service IAM role"
  value       = module.ecs_service.iam_role_arn
}

output "iam_role_name" {
  description = "Name of the service IAM role"
  value       = module.ecs_service.iam_role_name
}

output "task_exec_iam_role_arn" {
  description = "ARN of the task execution IAM role"
  value       = module.ecs_service.task_exec_iam_role_arn
}

output "task_exec_iam_role_name" {
  description = "Name of the task execution IAM role"
  value       = module.ecs_service.task_exec_iam_role_name
}

output "tasks_iam_role_arn" {
  description = "ARN of the tasks IAM role"
  value       = module.ecs_service.tasks_iam_role_arn
}

output "tasks_iam_role_name" {
  description = "Name of the tasks IAM role"
  value       = module.ecs_service.tasks_iam_role_name
}

output "autoscaling_policies" {
  description = "Map of autoscaling policies and their attributes"
  value       = module.ecs_service.autoscaling_policies
}

output "autoscaling_scheduled_actions" {
  description = "Map of autoscaling scheduled actions and their attributes"
  value       = module.ecs_service.autoscaling_scheduled_actions
}

output "container_definitions" {
  description = "Container definitions used for the task definition"
  value       = module.ecs_service.container_definitions
  sensitive   = true
}
