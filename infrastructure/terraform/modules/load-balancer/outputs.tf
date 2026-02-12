output "alb_id" {
  description = "ID of the Application Load Balancer"
  value       = module.alb.id
}

output "alb_arn" {
  description = "ARN of the Application Load Balancer"
  value       = module.alb.arn
}

output "alb_arn_suffix" {
  description = "ARN suffix of the Application Load Balancer for use with CloudWatch metrics"
  value       = module.alb.arn_suffix
}

output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = module.alb.dns_name
}

output "alb_zone_id" {
  description = "Zone ID of the Application Load Balancer for Route53 alias records"
  value       = module.alb.zone_id
}

output "security_group_ids" {
  description = "Security group IDs attached to the load balancer"
  value       = module.alb.security_group_id
}

# Target group ARNs keyed by the same keys passed in var.target_groups
output "target_group_arns" {
  description = "Map of target group key to ARN"
  value       = { for key, _ in var.target_groups : key => module.alb.target_groups[key].arn }
}
