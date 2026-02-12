# ==============================================================================
# ECS Fargate Wrapper Module - Outputs
# ==============================================================================

# Cluster
output "cluster_id" {
  description = "ID of the ECS cluster"
  value       = module.cluster.id
}

output "cluster_arn" {
  description = "ARN of the ECS cluster"
  value       = module.cluster.arn
}

output "cluster_name" {
  description = "Name of the ECS cluster"
  value       = module.cluster.name
}

# Service
output "service_id" {
  description = "ID of the ECS service"
  value       = module.service.id
}

output "service_name" {
  description = "Name of the ECS service"
  value       = module.service.name
}

# Task Definition
output "task_definition_arn" {
  description = "Full ARN of the task definition (includes revision)"
  value       = module.service.task_definition_arn
}

# IAM
output "task_exec_iam_role_arn" {
  description = "ARN of the task execution IAM role"
  value       = module.service.task_exec_iam_role_arn
}

output "tasks_iam_role_arn" {
  description = "ARN of the task IAM role (application permissions)"
  value       = module.service.tasks_iam_role_arn
}

# Security Group
output "security_group_id" {
  description = "ID of the ECS service security group"
  value       = module.service.security_group_id
}

# Autoscaling
output "autoscaling_policies" {
  description = "Map of autoscaling policies"
  value       = try(module.service.autoscaling_policies, {})
}

# Container log group names (for external reference)
output "container_log_groups" {
  description = "Map of container name to CloudWatch log group name"
  value = {
    for name, _ in var.container_definitions :
    name => "${var.context.environment}/ecs/${var.context.project}/${name}"
  }
}
