# ============================================================================
# Application Load Balancer
# ============================================================================

locals {
  acm_cert_arn = var.domain != "" ? module.acm[0].certificate_arn : var.acm_certificate_arn
}

module "alb" {
  source = "../modules/aws_alb"

  context = local.context
  name    = "alb"

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
      backend_port     = 8000
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
    https = {
      port            = 443
      protocol        = "HTTPS"
      ssl_policy      = "ELBSecurityPolicy-TLS13-1-2-2021-06"
      certificate_arn = local.acm_cert_arn
      forward         = { target_group_key = "backend" }
    }
    http_redirect = {
      port     = 80
      protocol = "HTTP"
      redirect = {
        port        = "443"
        protocol    = "HTTPS"
        status_code = "HTTP_301"
      }
    }
  }
}
