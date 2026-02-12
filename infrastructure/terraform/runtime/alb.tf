# ============================================================================
# Application Load Balancer
# ============================================================================

module "alb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "~> 9.0"

  # Naming standard: project-resource-name-env (flat)
  name               = "${var.project}-alb-${var.environment}"
  load_balancer_type = "application"
  internal           = false

  vpc_id          = module.vpc.vpc_id
  subnets         = module.vpc.public_subnet_ids
  security_groups = [module.alb_security_group.security_group_id]

  enable_deletion_protection       = var.environment == "production"
  enable_http2                     = true
  enable_cross_zone_load_balancing = true

  # Target Groups
  target_groups = {
    backend = {
      # Naming standard: project-resource-name-env (flat)
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
        path                = "/api/health"
        protocol            = "HTTP"
        matcher             = "200"
      }

      deregistration_delay = 30

      # Stickiness configuration
      stickiness = {
        enabled         = false
        type            = "lb_cookie"
        cookie_duration = 86400
      }

      # ECS targets are registered by the ECS service, not the ALB module
      create_attachment = false
    }
  }

  # Listeners
  listeners = {
    http = {
      port     = 80
      protocol = "HTTP"

      forward = {
        target_group_key = "backend"
      }
    }
  }

  tags = merge(
    local.context.common_tags,
    {
      Name      = "${var.project}-alb-${var.environment}"
      Component = "load-balancer"
    }
  )
}
