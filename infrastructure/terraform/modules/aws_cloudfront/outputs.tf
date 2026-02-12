output "cloudfront_distribution_id" {
  description = "The identifier for the CloudFront distribution"
  value       = module.cloudfront.cloudfront_distribution_id
}

output "cloudfront_distribution_arn" {
  description = "The ARN (Amazon Resource Name) for the CloudFront distribution"
  value       = module.cloudfront.cloudfront_distribution_arn
}

output "cloudfront_distribution_domain_name" {
  description = "The domain name corresponding to the CloudFront distribution"
  value       = module.cloudfront.cloudfront_distribution_domain_name
}

output "cloudfront_distribution_hosted_zone_id" {
  description = "The CloudFront Route 53 zone ID for alias records"
  value       = module.cloudfront.cloudfront_distribution_hosted_zone_id
}

output "cloudfront_distribution_status" {
  description = "The current status of the distribution (Deployed or InProgress)"
  value       = module.cloudfront.cloudfront_distribution_status
}

output "cloudfront_distribution_etag" {
  description = "The current version of the distribution's information"
  value       = module.cloudfront.cloudfront_distribution_etag
}

output "cloudfront_distribution_caller_reference" {
  description = "Internal value used by CloudFront to allow future updates to the distribution configuration"
  value       = module.cloudfront.cloudfront_distribution_caller_reference
}

output "cloudfront_origin_access_identity_ids" {
  description = "The IDs of the CloudFront origin access identities"
  value       = try(module.cloudfront.cloudfront_origin_access_identity_ids, [])
}

output "cloudfront_origin_access_identity_iam_arns" {
  description = "The IAM ARNs of the CloudFront origin access identities"
  value       = try(module.cloudfront.cloudfront_origin_access_identity_iam_arns, [])
}

output "cloudfront_origin_access_controls" {
  description = "The origin access controls created for the distribution"
  value       = try(module.cloudfront.cloudfront_origin_access_controls, {})
}

output "cloudfront_monitoring_subscription_id" {
  description = "The ID of the CloudFront monitoring subscription"
  value       = try(module.cloudfront.cloudfront_monitoring_subscription_id, null)
}
