/**
 * # ACM Certificate Module
 *
 * Provisions an ACM SSL/TLS certificate with DNS validation.
 *
 * Supports two modes:
 * - **Managed validation**: When `route53_zone_id` is provided, uses the
 *   community module to automatically create DNS validation records and
 *   wait for validation.
 * - **External validation**: When `route53_zone_id` is empty, creates a
 *   bare `aws_acm_certificate` resource. DNS validation records must be
 *   created manually in the external DNS account.
 */

locals {
  certificate_name  = "${var.context.project}-${var.context.environment}-cert"
  managed_route53   = var.route53_zone_id != ""

  tags = merge(
    var.context.common_tags,
    {
      Name      = local.certificate_name
      Component = "acm"
    }
  )
}

# ============================================================================
# Mode 1 – Managed validation via Route53 (community module)
# ============================================================================

module "acm" {
  source  = "terraform-aws-modules/acm/aws"
  version = "~> 6.0"

  count = local.managed_route53 ? 1 : 0

  domain_name               = var.domain
  subject_alternative_names = var.subject_alternative_names != null ? var.subject_alternative_names : ["*.${var.domain}"]

  zone_id = var.route53_zone_id

  wait_for_validation = var.wait_for_validation

  validation_method                  = "DNS"
  validation_allow_overwrite_records = true
  validation_timeout                 = var.validation_timeout

  tags = local.tags
}

# ============================================================================
# Mode 2 – External validation (no Route53 zone available)
# ============================================================================

resource "aws_acm_certificate" "this" {
  count = local.managed_route53 ? 0 : 1

  domain_name               = var.domain
  subject_alternative_names = var.subject_alternative_names != null ? var.subject_alternative_names : ["*.${var.domain}"]
  validation_method         = "DNS"

  tags = local.tags

  lifecycle {
    create_before_destroy = true
  }
}
