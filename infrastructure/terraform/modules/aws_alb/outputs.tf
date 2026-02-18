output "id" {
  description = "The ID of the load balancer"
  value       = module.alb.id
}

output "arn" {
  description = "The ARN of the load balancer"
  value       = module.alb.arn
}

output "arn_suffix" {
  description = "ARN suffix for use with CloudWatch Metrics"
  value       = module.alb.arn_suffix
}

output "dns_name" {
  description = "The DNS name of the load balancer"
  value       = module.alb.dns_name
}

output "zone_id" {
  description = "The canonical hosted zone ID of the load balancer (to be used in a Route 53 Alias record)"
  value       = module.alb.zone_id
}

output "security_group_id" {
  description = "ID of the security group"
  value       = module.alb.security_group_id
}

output "target_groups" {
  description = "Map of target groups created and their attributes"
  value       = module.alb.target_groups
}

output "listeners" {
  description = "Map of listeners created and their attributes"
  value       = module.alb.listeners
}

output "listener_rules" {
  description = "Map of listeners rules created and their attributes"
  value       = module.alb.listener_rules
}

output "route53_records" {
  description = "Map of Route53 records created and their attributes"
  value       = module.alb.route53_records
}
