# ============================================================================
# Application Load Balancer
# ============================================================================

locals {
  enable_https = var.acm_certificate_arn != ""

  all_listeners = {
    https = {
      enabled         = local.enable_https
      port            = 443
      protocol        = "HTTPS"
      ssl_policy      = "ELBSecurityPolicy-TLS13-1-2-2021-06"
      certificate_arn = var.acm_certificate_arn
      forward         = { target_group_key = "backend" }
      redirect        = null
    }
    http_redirect = {
      enabled         = local.enable_https
      port            = 80
      protocol        = "HTTP"
      ssl_policy      = null
      certificate_arn = null
      forward         = null
      redirect = {
        port        = "443"
        protocol    = "HTTPS"
        status_code = "HTTP_301"
      }
    }
    http = {
      enabled         = !local.enable_https
      port            = 80
      protocol        = "HTTP"
      ssl_policy      = null
      certificate_arn = null
      forward         = { target_group_key = "backend" }
      redirect        = null
    }
  }
}

module "alb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "~> 10.0"

  name               = "${var.project}-alb-${var.environment}"
  load_balancer_type = "application"
  internal           = false

  vpc_id          = module.vpc.vpc_id
  subnets         = module.vpc.public_subnet_ids
  security_groups = [module.alb_security_group.security_group_id]

  enable_deletion_protection       = var.environment == "production"
  enable_http2                     = true
  enable_cross_zone_load_balancing = true

  target_groups = {
    backend = {
      name             = "${var.project}-backend-tg-${var.environment}"
      backend_protocol = "HTTP"
      backend_port     = 80
      target_type      = "ip"

      health_check = {
        enabled             = true
        healthy_threshold   = 2
        unhealthy_threshold = 3
        timeout             = 5
        interval            = 30
        path                = "/api/v1/utils/health-check/"
        protocol            = "HTTP"
        matcher             = "200"
      }

      deregistration_delay = 30

      stickiness = {
        enabled         = false
        type            = "lb_cookie"
        cookie_duration = 86400
      }

      create_attachment = false
    }
  }

  listeners = {
    for k, v in local.all_listeners : k => {
      port            = v.port
      protocol        = v.protocol
      ssl_policy      = v.ssl_policy
      certificate_arn = v.certificate_arn
      forward         = v.forward
      redirect        = v.redirect
    } if v.enabled
  }

  tags = merge(
    local.context.common_tags,
    {
      Name      = "${var.project}-alb-${var.environment}"
      Component = "load-balancer"
    }
  )
}
