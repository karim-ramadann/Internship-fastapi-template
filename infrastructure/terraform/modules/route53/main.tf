# Route53 Hosted Zone
resource "aws_route53_zone" "main" {
  count = var.create_hosted_zone ? 1 : 0
  name  = var.domain

  tags = merge(
    var.context.common_tags,
    {
      Name = "${var.context.project}-${var.context.environment}-zone"
    }
  )
}

# Use existing hosted zone if not creating new one
data "aws_route53_zone" "existing" {
  count        = var.create_hosted_zone ? 0 : 1
  name         = var.domain
  private_zone = false
}

locals {
  zone_id = var.create_hosted_zone ? aws_route53_zone.main[0].zone_id : data.aws_route53_zone.existing[0].zone_id
}

# ALB Alias Records - Backend API
resource "aws_route53_record" "backend" {
  zone_id = local.zone_id
  name    = "api.${var.domain}"
  type    = "A"

  alias {
    name                   = var.alb_dns_name
    zone_id                = var.alb_zone_id
    evaluate_target_health = true
  }
}

# ALB Alias Records - Frontend Dashboard
resource "aws_route53_record" "frontend" {
  zone_id = local.zone_id
  name    = "dashboard.${var.domain}"
  type    = "A"

  alias {
    name                   = var.alb_dns_name
    zone_id                = var.alb_zone_id
    evaluate_target_health = true
  }
}

# ALB Alias Records - Adminer
resource "aws_route53_record" "adminer" {
  zone_id = local.zone_id
  name    = "adminer.${var.domain}"
  type    = "A"

  alias {
    name                   = var.alb_dns_name
    zone_id                = var.alb_zone_id
    evaluate_target_health = true
  }
}
