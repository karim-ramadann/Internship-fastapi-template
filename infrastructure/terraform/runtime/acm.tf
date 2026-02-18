# ============================================================================
# ACM Certificate (DNS validation records managed in external account)
# ============================================================================

module "acm" {
  source = "../modules/aws_acm"

  count = var.domain != "" ? 1 : 0

  context = local.context
  domain  = var.domain

  # No Route53 zone in this account – DNS validation records must be
  # created manually in the external hosted-zone account.
  # route53_zone_id = ""   (default)
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
