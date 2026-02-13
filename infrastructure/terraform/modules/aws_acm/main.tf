/**
 * # ACM Certificate Module
 *
 * Thin wrapper around [terraform-aws-modules/acm/aws](https://registry.terraform.io/modules/terraform-aws-modules/acm/aws/latest).
 *
 * This module provides organization-wide standards for SSL/TLS certificates:
 * - Automatic DNS validation via Route53
 * - Wildcard certificate support (*.domain.com)
 * - Standard tagging with project and environment
 * - Automatic validation waiting (no manual intervention)
 */

locals {
  certificate_name = "${var.context.project}-${var.context.environment}-cert"

  tags = merge(
    var.context.common_tags,
    {
      Name      = local.certificate_name
      Component = "acm"
    }
  )
}

module "acm" {
  source  = "terraform-aws-modules/acm/aws"
  version = "~> 6.0"

  domain_name               = var.domain
  subject_alternative_names = var.subject_alternative_names != null ? var.subject_alternative_names : ["*.${var.domain}"]

  zone_id = var.route53_zone_id

  # Wait for validation to complete
  wait_for_validation = var.wait_for_validation

  # Validation configuration
  validation_method                  = "DNS"
  validation_allow_overwrite_records = true
  validation_timeout                 = var.validation_timeout

  tags = local.tags
}
