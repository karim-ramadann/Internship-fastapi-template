/**
 * # ACM Certificate Module
 *
 * Provisions an ACM SSL/TLS certificate with DNS validation.
 *
 * Supports two modes:
 * - **Managed validation**: When `route53_zone_id` is provided, creates
 *   DNS validation records in Route53 and waits for validation.
 * - **External validation**: When `route53_zone_id` is empty, creates a
 *   bare `aws_acm_certificate` resource. DNS validation records must be
 *   created manually in the external DNS account.
 */

locals {
  certificate_name = "${var.context.project}-${var.context.environment}-cert"
  managed_route53  = var.route53_zone_id != ""

  tags = merge(
    var.context.common_tags,
    {
      Name      = local.certificate_name
      Component = "acm"
    }
  )
}

# ============================================================================
# ACM Certificate
# ============================================================================

resource "aws_acm_certificate" "this" {
  domain_name               = var.domain
  subject_alternative_names = var.subject_alternative_names != null ? var.subject_alternative_names : ["*.${var.domain}"]
  validation_method         = "DNS"

  tags = local.tags

  lifecycle {
    create_before_destroy = true
  }
}

# ============================================================================
# Mode 1 – Managed validation via Route53
# ============================================================================

resource "aws_route53_record" "validation" {
  for_each = local.managed_route53 ? {
    for dvo in aws_acm_certificate.this.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      type   = dvo.resource_record_type
      record = dvo.resource_record_value
    }
  } : {}

  allow_overwrite = true
  name            = each.value.name
  type            = each.value.type
  zone_id         = var.route53_zone_id
  records         = [each.value.record]
  ttl             = 60
}

resource "aws_acm_certificate_validation" "this" {
  count = local.managed_route53 && var.wait_for_validation ? 1 : 0

  certificate_arn         = aws_acm_certificate.this.arn
  validation_record_fqdns = [for record in aws_route53_record.validation : record.fqdn]

  timeouts {
    create = var.validation_timeout
  }
}
