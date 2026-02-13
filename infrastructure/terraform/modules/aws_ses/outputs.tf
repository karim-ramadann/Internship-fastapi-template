output "ses_domain_identity_arn" {
  description = "ARN of the SES domain identity"
  value       = module.ses.ses_domain_identity_arn
}

output "ses_domain_identity_verification_token" {
  description = "Verification token for the domain identity"
  value       = module.ses.ses_domain_identity_verification_token
}

output "ses_configuration_set_name" {
  description = "Name of the SES configuration set"
  value       = try(module.ses.ses_configuration_set_name, null)
}
