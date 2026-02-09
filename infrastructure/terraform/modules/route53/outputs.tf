output "zone_id" {
  description = "ID of the Route53 hosted zone"
  value       = local.zone_id
}

output "zone_name" {
  description = "Name of the Route53 hosted zone"
  value       = var.domain
}

output "zone_name_servers" {
  description = "Name servers for the hosted zone (if created)"
  value       = var.create_hosted_zone ? aws_route53_zone.main[0].name_servers : null
}

output "backend_fqdn" {
  description = "Fully qualified domain name for backend API"
  value       = aws_route53_record.backend.fqdn
}

output "frontend_fqdn" {
  description = "Fully qualified domain name for frontend dashboard"
  value       = aws_route53_record.frontend.fqdn
}

output "adminer_fqdn" {
  description = "Fully qualified domain name for adminer"
  value       = aws_route53_record.adminer.fqdn
}
