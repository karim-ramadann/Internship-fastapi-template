output "certificate_arn" {
  description = "ARN of the ACM certificate"
  value       = aws_acm_certificate.this.arn
}

output "certificate_domain_name" {
  description = "Primary domain name of the certificate"
  value       = var.domain
}

output "certificate_status" {
  description = "Status of the ACM certificate"
  value       = aws_acm_certificate.this.status
}

output "validation_domains" {
  description = "Domain validation options (useful when DNS records are managed externally)"
  value       = aws_acm_certificate.this.domain_validation_options
}

output "distinct_domain_names" {
  description = "List of distinct domain names for certificate validation"
  value       = distinct(concat([var.domain], var.subject_alternative_names != null ? var.subject_alternative_names : ["*.${var.domain}"]))
}

output "validation_route53_record_fqdns" {
  description = "List of FQDNs built using the zone domain and name (only available with managed Route53)"
  value       = local.managed_route53 ? [for record in aws_route53_record.validation : record.fqdn] : []
}
