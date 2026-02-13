/**
 * # CloudFront Distribution Module
 *
 * Thin wrapper around [terraform-aws-modules/cloudfront/aws](https://registry.terraform.io/modules/terraform-aws-modules/cloudfront/aws/latest).
 *
 * This module provides organization-wide standards for CloudFront distributions:
 * - Standard naming and tagging conventions
 * - Security headers via response headers policy
 * - Origin access control for S3 origins
 * - Price class configuration
 * - SSL/TLS certificate integration
 * - Custom error responses and caching behavior
 */

locals {
  distribution_name = "${var.context.project}-${var.context.environment}-${var.name}"

  tags = merge(
    var.context.common_tags,
    {
      Name      = local.distribution_name
      Component = "cloudfront"
    },
    var.tags
  )
}

module "cloudfront" {
  source  = "terraform-aws-modules/cloudfront/aws"
  version = "~> 6.0"

  comment             = var.comment != null ? var.comment : "CloudFront distribution for ${local.distribution_name}"
  enabled             = var.enabled
  is_ipv6_enabled     = var.is_ipv6_enabled
  price_class         = var.price_class
  retain_on_delete    = var.retain_on_delete
  wait_for_deployment = var.wait_for_deployment
  web_acl_id          = var.web_acl_id

  # Origin configuration
  origin = var.origin

  # Origin groups for failover
  origin_group = var.origin_group

  # Default cache behavior
  default_cache_behavior = var.default_cache_behavior

  # Ordered cache behaviors
  ordered_cache_behavior = var.ordered_cache_behavior

  # Viewer certificate
  viewer_certificate = var.viewer_certificate

  # Geographic restrictions
  geo_restriction = var.geo_restriction

  # Custom error responses
  custom_error_response = var.custom_error_response

  # Logging configuration
  logging_config = var.logging_config

  # Default root object
  default_root_object = var.default_root_object

  # Aliases (CNAMEs)
  aliases = var.aliases

  tags = local.tags
}
