# VPC Outputs
output "vpc_id" {
  description = "ID of the VPC"
  value       = module.networking.vpc_id
}

# ALB Outputs
output "alb_dns_name" {
  description = "DNS name of the ALB - use this for DNS CNAME records"
  value       = module.load_balancer.alb_dns_name
}

output "alb_zone_id" {
  description = "Zone ID of the ALB for Route53 alias records"
  value       = module.load_balancer.alb_zone_id
}

# RDS Outputs
output "rds_endpoint" {
  description = "RDS instance endpoint"
  value       = module.database.rds_endpoint
  sensitive   = true
}

# ECR Outputs
output "ecr_backend_repository_url" {
  description = "URL of the backend ECR repository"
  value       = module.ecr.backend_repository_url
}

output "ecr_frontend_repository_url" {
  description = "URL of the frontend ECR repository"
  value       = module.ecr.frontend_repository_url
}

# ECS Cluster Outputs
output "ecs_cluster_id" {
  description = "ID of the ECS cluster"
  value       = module.ecs_fargate.cluster_id
}

output "ecs_cluster_arn" {
  description = "ARN of the ECS cluster"
  value       = module.ecs_fargate.cluster_arn
}

output "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  value       = module.ecs_fargate.cluster_name
}

output "ecs_service_id" {
  description = "ID of the ECS service"
  value       = module.ecs_fargate.service_id
}

output "ecs_service_name" {
  description = "Name of the ECS service"
  value       = module.ecs_fargate.service_name
}

output "task_definition_arn" {
  description = "ARN of the task definition"
  value       = module.ecs_fargate.task_definition_arn
}

# Service Discovery Outputs
output "service_discovery_namespace" {
  description = "Name of the Cloud Map namespace"
  value       = module.service_discovery.namespace_name
}

# CloudWatch Outputs
output "cloudwatch_log_groups" {
  description = "CloudWatch log group names"
  value       = module.ecs_fargate.container_log_groups
}

# Route53 Outputs
output "route53_zone_id" {
  description = "ID of the Route53 hosted zone"
  value       = module.route53.zone_id
}

output "route53_name_servers" {
  description = "Name servers for the hosted zone (update your domain registrar)"
  value       = module.route53.zone_name_servers
}

# ACM Certificate Outputs
output "certificate_arn" {
  description = "ARN of the validated ACM certificate"
  value       = module.acm.certificate_arn
}

# Deployment Information
output "application_urls" {
  description = "URLs for accessing the application"
  value = {
    backend  = "https://${module.route53.backend_fqdn}"
    frontend = "https://${module.route53.frontend_fqdn}"
    adminer  = "https://${module.route53.adminer_fqdn}"
    api_docs = "https://${module.route53.backend_fqdn}/docs"
  }
}
