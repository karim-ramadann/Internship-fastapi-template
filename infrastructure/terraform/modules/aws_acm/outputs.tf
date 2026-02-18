output "certificate_arn" {
  description = "ARN of the ACM certificate"
  value       = local.managed_route53 ? module.acm[0].acm_certificate_arn : aws_acm_certificate.this[0].arn
}

output "certificate_domain_name" {
  description = "Primary domain name of the certificate"
  value       = var.domain
}

output "certificate_status" {
  description = "Status of the ACM certificate"
  value       = local.managed_route53 ? module.acm[0].acm_certificate_status : aws_acm_certificate.this[0].status
}

output "validation_domains" {
  description = "Domain validation options (useful when DNS records are managed externally)"
  value       = local.managed_route53 ? module.acm[0].acm_certificate_domain_validation_options : aws_acm_certificate.this[0].domain_validation_options
}

output "distinct_domain_names" {
  description = "List of distinct domain names for certificate validation"
  value       = local.managed_route53 ? module.acm[0].distinct_domain_names : [var.domain]
}

output "validation_route53_record_fqdns" {
  description = "List of FQDNs built using the zone domain and name (only available with managed Route53)"
  value       = local.managed_route53 ? module.acm[0].validation_route53_record_fqdns : []
}
