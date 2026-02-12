/**
 * # Application Load Balancer Module
 *
 * Thin wrapper around [terraform-aws-modules/alb/aws](https://registry.terraform.io/modules/terraform-aws-modules/alb/aws/latest).
 *
 * Manages the ALB, target groups, HTTPS/HTTP listeners, and host-based routing rules.
 * Business logic (which hosts route where) is driven by variables, not hardcoded.
 */

locals {
  name_prefix = "${var.context.project}-${var.context.environment}"

  tags = merge(
    var.context.common_tags,
    {
      Name      = "${local.name_prefix}-alb"
      Component = "load-balancer"
    }
  )

  # Build target groups for the community module
  target_groups = { for key, tg in var.target_groups : key => {
    name             = "${local.name_prefix}-${key}-tg"
    backend_port     = tg.port
    backend_protocol = tg.protocol
    target_type      = tg.target_type

    deregistration_delay = tg.deregistration_delay

    health_check = {
      enabled             = true
      healthy_threshold   = 2
      unhealthy_threshold = 3
      timeout             = 5
      interval            = 30
      path                = tg.health_check_path
      protocol            = tg.protocol
      matcher             = "200"
    }

    # ECS targets are registered by the ECS service, not the ALB module
    create_attachment = false

    tags = merge(local.tags, { Name = "${local.name_prefix}-${key}-tg" })
  }}
}

module "alb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "~> 9.0"

  name               = "${local.name_prefix}-alb"
  load_balancer_type = var.load_balancer_type
  internal           = var.internal

  vpc_id          = var.vpc_id
  subnets         = var.subnets
  security_groups = var.security_groups

  enable_deletion_protection       = var.enable_deletion_protection
  enable_http2                     = var.enable_http2
  enable_cross_zone_load_balancing = var.enable_cross_zone_load_balancing

  access_logs = var.access_logs

  # ---------------------------------------------------------------------------
  # Target Groups
  # ---------------------------------------------------------------------------
  target_groups = local.target_groups

  # ---------------------------------------------------------------------------
  # Listeners
  # ---------------------------------------------------------------------------
  listeners = {
    # HTTP → HTTPS redirect
    http = {
      port     = 80
      protocol = "HTTP"

      redirect = {
        port        = "443"
        protocol    = "HTTPS"
        status_code = "HTTP_301"
      }
    }

    # HTTPS listener with default 404
    https = {
      port            = 443
      protocol        = "HTTPS"
      ssl_policy      = "ELBSecurityPolicy-TLS13-1-2-2021-06"
      certificate_arn = var.certificate_arn

      fixed_response = {
        content_type = "text/plain"
        message_body = "Not Found"
        status_code  = "404"
      }

      # Host-based routing rules
      rules = { for key, rule in var.host_rules : key => {
        priority = rule.priority

        actions = [{
          type             = "forward"
          target_group_key = rule.target_group_key
        }]

        conditions = [{
          host_header = {
            values = [rule.host]
          }
        }]
      }}
    }
  }

  tags = local.tags
}
