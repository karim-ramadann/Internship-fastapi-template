output "bucket_id" {
  description = "Name of the bucket"
  value       = module.s3_bucket.s3_bucket_id
}

output "bucket_arn" {
  description = "ARN of the bucket"
  value       = module.s3_bucket.s3_bucket_arn
}

output "bucket_domain_name" {
  description = "Domain name of the bucket"
  value       = module.s3_bucket.s3_bucket_bucket_domain_name
}

output "bucket_regional_domain_name" {
  description = "Regional domain name of the bucket"
  value       = module.s3_bucket.s3_bucket_bucket_regional_domain_name
}

output "bucket_website_endpoint" {
  description = "Website endpoint of the bucket (if website hosting enabled)"
  value       = module.s3_bucket.s3_bucket_website_endpoint
}

output "bucket_website_domain" {
  description = "Website domain of the bucket (if website hosting enabled)"
  value       = module.s3_bucket.s3_bucket_website_domain
}
