# ============================================================================
# ACM Certificate (DNS validation records managed in external account)
# ============================================================================

resource "aws_acm_certificate" "main" {
  count = var.domain != "" ? 1 : 0

  domain_name               = var.domain
  subject_alternative_names = ["*.${var.domain}"]
  validation_method         = "DNS"

  tags = merge(
    local.context.common_tags,
    {
      Name      = "${var.project}-cert-${var.environment}"
      Component = "acm"
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

# ============================================================================
# Route53 DNS Record → ALB (managed in external account)
# ============================================================================
# The A record pointing testing.digico.solutions to the ALB must be created
# in the hosted zone account. After `terraform apply`, use the ALB DNS name
# from the output to create the record:
#
#   Type:  A (Alias)
#   Name:  testing.digico.solutions
#   Value: <alb_dns_name output>
# ============================================================================
