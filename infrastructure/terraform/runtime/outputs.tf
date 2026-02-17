# ============================================================================
# Outputs - Key infrastructure resource identifiers and endpoints
# ============================================================================
# These outputs provide the information needed to access and manage
# the deployed infrastructure.
# ============================================================================

# VPC Outputs
output "vpc_id" {
  description = "ID of the VPC"
  value       = module.vpc.vpc_id
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC"
  value       = module.vpc.vpc_cidr_block
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = module.vpc.private_subnet_ids
}

output "database_subnet_ids" {
  description = "IDs of the database subnets"
  value       = module.vpc.database_subnet_ids
}

# ALB Outputs
output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = module.alb.dns_name
}

output "alb_arn" {
  description = "ARN of the Application Load Balancer"
  value       = module.alb.arn
}

output "alb_zone_id" {
  description = "Zone ID of the Application Load Balancer"
  value       = module.alb.zone_id
}

# ACM Outputs
output "acm_certificate_arn" {
  description = "ARN of the ACM certificate"
  value       = var.domain != "" ? aws_acm_certificate.main[0].arn : null
}

output "acm_validation_records" {
  description = "DNS validation records to create in the hosted zone account"
  value = var.domain != "" ? {
    for dvo in aws_acm_certificate.main[0].domain_validation_options : dvo.domain_name => {
      name  = dvo.resource_record_name
      type  = dvo.resource_record_type
      value = dvo.resource_record_value
    }
  } : {}
}

output "alb_target_group_arn" {
  description = "ARN of the backend target group"
  value       = module.alb.target_groups["backend"].arn
}

# Security Group Outputs
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

# ECR Outputs
output "ecr_repository_url" {
  description = "URL of the ECR repository for backend images"
  value       = module.ecr_backend.repository_url
}

output "ecr_repository_arn" {
  description = "ARN of the ECR repository"
  value       = module.ecr_backend.repository_arn
}

# RDS Outputs
output "rds_endpoint" {
  description = "RDS instance endpoint (host:port)"
  value       = module.database.rds_endpoint
}

output "rds_address" {
  description = "RDS instance address (host only)"
  value       = module.database.rds_address
}

output "rds_port" {
  description = "RDS instance port"
  value       = module.database.rds_port
}

output "rds_database_name" {
  description = "Name of the database"
  value       = module.database.db_name
}

output "rds_instance_id" {
  description = "Identifier of the RDS instance"
  value       = module.database.db_instance_id
}

# Secrets Manager Outputs
output "db_credentials_secret_arn" {
  description = "ARN of the Secrets Manager secret containing database credentials"
  value       = module.database.secrets_manager_secret_arn
}

output "app_secrets_arn" {
  description = "ARN of the Secrets Manager secret containing application secrets"
  value       = aws_secretsmanager_secret.app_secrets.arn
}

# ECS Cluster Outputs
output "ecs_cluster_id" {
  description = "ID of the ECS cluster"
  value       = module.ecs_cluster.cluster_id
}

output "ecs_cluster_arn" {
  description = "ARN of the ECS cluster"
  value       = module.ecs_cluster.cluster_arn
}

output "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  value       = module.ecs_cluster.cluster_name
}

# ECS Service Outputs
output "ecs_service_id" {
  description = "ARN of the ECS service"
  value       = module.ecs_service_backend.service_id
}

output "ecs_service_name" {
  description = "Name of the ECS service"
  value       = module.ecs_service_backend.service_name
}

output "ecs_task_definition_arn" {
  description = "ARN of the task definition"
  value       = module.ecs_service_backend.task_definition_arn
}

output "ecs_task_execution_role_arn" {
  description = "ARN of the task execution IAM role"
  value       = module.ecs_service_backend.task_exec_iam_role_arn
}

output "ecs_task_role_arn" {
  description = "ARN of the task IAM role"
  value       = module.ecs_service_backend.tasks_iam_role_arn
}

# Environment Information
output "environment" {
  description = "Current environment name"
  value       = var.environment
}

output "aws_region" {
  description = "AWS region"
  value       = var.aws_region
}

# Useful Instructions
output "deployment_instructions" {
  description = "Instructions for deploying the application"
  value       = <<-EOT
    
    ====================================================================================================
    DEPLOYMENT INSTRUCTIONS
    ====================================================================================================
    
    1. Build and Push Docker Image:
       
       # Login to ECR
       aws ecr get-login-password --region ${var.aws_region} | docker login --username AWS --password-stdin ${module.ecr_backend.repository_url}
       
       # Build the image
       docker build -t ${var.project}-backend:${var.backend_image_tag} ./backend
       
       # Tag and push
       docker tag ${var.project}-backend:${var.backend_image_tag} ${module.ecr_backend.repository_url}:${var.backend_image_tag}
       docker push ${module.ecr_backend.repository_url}:${var.backend_image_tag}
    
    2. Access the Application:
       
       Backend API: http://${module.alb.dns_name}
       Health Check: http://${module.alb.dns_name}/api/health
    
    3. View Logs:
       
       aws logs tail /ecs/${var.environment}/${var.project}/backend --follow --region ${var.aws_region}
    
    4. Update ECS Service (force new deployment):
       
       aws ecs update-service --cluster ${module.ecs_cluster.cluster_name} --service ${module.ecs_service_backend.service_name} --force-new-deployment --region ${var.aws_region}
    
    ====================================================================================================
  EOT
}
