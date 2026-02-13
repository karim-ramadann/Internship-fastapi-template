output "cluster_arn" {
  description = "ARN that identifies the cluster"
  value       = module.ecs_cluster.cluster_arn
}

output "cluster_id" {
  description = "ID that identifies the cluster"
  value       = module.ecs_cluster.cluster_id
}

output "cluster_name" {
  description = "Name that identifies the cluster"
  value       = module.ecs_cluster.cluster_name
}

output "cluster_capacity_providers" {
  description = "Map of cluster capacity providers created and their attributes"
  value       = module.ecs_cluster.cluster_capacity_providers
}

output "cloudwatch_log_group_name" {
  description = "Name of CloudWatch log group created for the cluster"
  value       = module.ecs_cluster.cloudwatch_log_group_name
}

output "cloudwatch_log_group_arn" {
  description = "ARN of CloudWatch log group created for the cluster"
  value       = module.ecs_cluster.cloudwatch_log_group_arn
}

output "infrastructure_iam_role_arn" {
  description = "ARN of IAM role created for ECS infrastructure"
  value       = module.ecs_cluster.infrastructure_iam_role_arn
}

output "infrastructure_iam_role_name" {
  description = "Name of IAM role created for ECS infrastructure"
  value       = module.ecs_cluster.infrastructure_iam_role_name
}

output "infrastructure_iam_role_unique_id" {
  description = "Stable and unique string identifying the IAM role"
  value       = module.ecs_cluster.infrastructure_iam_role_unique_id
}

output "node_iam_role_arn" {
  description = "ARN of IAM role created for ECS nodes"
  value       = module.ecs_cluster.node_iam_role_arn
}

output "node_iam_role_name" {
  description = "Name of IAM role created for ECS nodes"
  value       = module.ecs_cluster.node_iam_role_name
}

output "node_iam_role_unique_id" {
  description = "Stable and unique string identifying the node IAM role"
  value       = module.ecs_cluster.node_iam_role_unique_id
}

output "node_iam_instance_profile_arn" {
  description = "ARN assigned by AWS to the instance profile"
  value       = module.ecs_cluster.node_iam_instance_profile_arn
}

output "node_iam_instance_profile_id" {
  description = "Instance profile's ID"
  value       = module.ecs_cluster.node_iam_instance_profile_id
}

output "node_iam_instance_profile_unique" {
  description = "Stable and unique string identifying the IAM instance profile"
  value       = module.ecs_cluster.node_iam_instance_profile_unique
}

output "task_exec_iam_role_arn" {
  description = "ARN of IAM role created for ECS task execution"
  value       = module.ecs_cluster.task_exec_iam_role_arn
}

output "task_exec_iam_role_name" {
  description = "Name of IAM role created for ECS task execution"
  value       = module.ecs_cluster.task_exec_iam_role_name
}

output "task_exec_iam_role_unique_id" {
  description = "Stable and unique string identifying the task execution IAM role"
  value       = module.ecs_cluster.task_exec_iam_role_unique_id
}
