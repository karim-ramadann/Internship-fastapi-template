output "certificate_arn" {
  description = "ARN of the validated ACM certificate"
  value       = module.acm.acm_certificate_arn
}

output "certificate_id" {
  description = "ID of the ACM certificate"
  value       = module.acm.acm_certificate_id
}

output "certificate_domain_name" {
  description = "Primary domain name of the certificate"
  value       = var.domain
}

output "certificate_status" {
  description = "Status of the ACM certificate"
  value       = module.acm.acm_certificate_status
}

output "validation_domains" {
  description = "List of domains used for certificate validation"
  value       = module.acm.acm_certificate_domain_validation_options
}

output "distinct_domain_names" {
  description = "List of distinct domain names for certificate validation"
  value       = module.acm.distinct_domain_names
}

output "validation_route53_record_fqdns" {
  description = "List of FQDNs built using the zone domain and name"
  value       = module.acm.validation_route53_record_fqdns
}
