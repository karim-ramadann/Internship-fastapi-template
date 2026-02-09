output "alb_security_group_id" {
  description = "ID of the ALB security group"
  value       = module.alb_security_group.security_group_id
}

output "ecs_security_group_id" {
  description = "ID of the ECS security group"
  value       = module.ecs_security_group.security_group_id
}

output "rds_security_group_id" {
  description = "ID of the RDS security group"
  value       = module.rds_security_group.security_group_id
}

output "ecs_task_execution_role_arn" {
  description = "ARN of the ECS task execution role"
  value       = aws_iam_role.ecs_task_execution_role.arn
}

output "ecs_task_role_arn" {
  description = "ARN of the ECS task role"
  value       = aws_iam_role.ecs_task_role.arn
}

output "ecs_instance_role_name" {
  description = "Name of the ECS EC2 instance role"
  value       = aws_iam_role.ecs_instance_role.name
}

output "ecs_instance_profile_name" {
  description = "Name of the ECS EC2 instance profile"
  value       = aws_iam_instance_profile.ecs_instance_profile.name
}

output "ecs_instance_profile_arn" {
  description = "ARN of the ECS EC2 instance profile"
  value       = aws_iam_instance_profile.ecs_instance_profile.arn
}
