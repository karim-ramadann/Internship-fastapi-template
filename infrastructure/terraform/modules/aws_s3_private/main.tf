/**
 * # S3 Private Bucket Module
 *
 * Thin wrapper around [terraform-aws-modules/s3-bucket/aws](https://registry.terraform.io/modules/terraform-aws-modules/s3-bucket/aws/latest).
 *
 * Standards enforced:
 * - Naming convention: `{project}-{name}-{environment}`
 * - All public access blocked by default
 * - Server-side encryption (SSE-S3) enabled
 * - Versioning enabled by default
 * - Environment-based lifecycle rules
 */

locals {
  bucket_name = "${var.context.project}-${var.name}-${var.context.environment}"

  tags = merge(
    var.context.common_tags,
    {
      Name      = local.bucket_name
      Component = "s3"
    },
    var.tags
  )
}

module "s3_bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "~> 4.0"

  bucket = local.bucket_name

  # Block all public access
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  # Versioning
  versioning = {
    enabled = var.enable_versioning
  }

  # Server-side encryption
  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        sse_algorithm     = var.kms_key_arn != null ? "aws:kms" : "AES256"
        kms_master_key_id = var.kms_key_arn
      }
      bucket_key_enabled = var.kms_key_arn != null
    }
  }

  # Lifecycle rules
  lifecycle_rule = var.lifecycle_rules

  # Force destroy for non-production
  force_destroy = var.context.environment != "production"

  # CORS
  cors_rule = var.cors_rules

  # Logging
  logging = var.logging

  tags = local.tags
}
