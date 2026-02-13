/**
 * # S3 Public Bucket Module
 *
 * Thin wrapper around [terraform-aws-modules/s3-bucket/aws](https://registry.terraform.io/modules/terraform-aws-modules/s3-bucket/aws/latest).
 *
 * Standards enforced:
 * - Naming convention: `{project}-{name}-{environment}`
 * - Public read access via bucket policy
 * - Server-side encryption (SSE-S3) enabled
 * - Designed for static assets, public downloads, or website hosting
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

  # Public access settings for public bucket
  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false

  # Versioning
  versioning = {
    enabled = var.enable_versioning
  }

  # Server-side encryption
  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        sse_algorithm = "AES256"
      }
    }
  }

  # Website hosting
  website = var.enable_website ? {
    index_document = var.index_document
    error_document = var.error_document
  } : {}

  # CORS
  cors_rule = var.cors_rules

  # Lifecycle rules
  lifecycle_rule = var.lifecycle_rules

  # Force destroy for non-production
  force_destroy = var.context.environment != "production"

  # Bucket policy for public read
  attach_policy = true
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "arn:aws:s3:::${local.bucket_name}/*"
      }
    ]
  })

  tags = local.tags
}
