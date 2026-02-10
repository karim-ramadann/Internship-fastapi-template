# ============================================================================
# NETWORKING - VPC, Subnets, DNS
# ============================================================================

# Networking Module (VPC with public/private subnets)
module "networking" {
  source = "./modules/networking"

  context = local.context

  vpc_cidr             = var.vpc_cidr
  availability_zones   = slice(data.aws_availability_zones.available.names, 0, 2)
  public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnet_cidrs = ["10.0.10.0/24", "10.0.11.0/24"]

  # NAT Gateway strategy (business logic - environment-specific)
  enable_nat_gateway     = true
  single_nat_gateway     = var.environment != "production"
  one_nat_gateway_per_az = var.environment == "production"
}

# Route53 Hosted Zone (must come before ACM for DNS validation)
module "route53" {
  source = "./modules/route53"

  context = local.context

  domain             = var.domain
  create_hosted_zone = var.create_hosted_zone

  # ALB DNS will be provided after load balancer is created
  alb_dns_name = module.load_balancer.alb_dns_name
  alb_zone_id  = module.load_balancer.alb_zone_id
}

# ACM Certificate (with automatic DNS validation)
module "acm" {
  source = "./modules/acm"

  context = local.context

  domain          = var.domain
  route53_zone_id = module.route53.zone_id
}

# ============================================================================
# LOAD BALANCING - ALB, Target Groups, Listeners, Rules
# ============================================================================

# Application Load Balancer (thin wrapper)
module "load_balancer" {
  source = "./modules/load-balancer"

  context = local.context

  vpc_id          = module.networking.vpc_id
  subnets         = module.networking.public_subnet_ids
  security_groups = [module.security.alb_security_group_id]

  # Business logic: enable deletion protection for production
  enable_deletion_protection = var.environment == "production"
}

# Backend Target Group
resource "aws_lb_target_group" "backend" {
  name        = "${local.name_prefix}-backend-tg"
  port        = 8000
  protocol    = "HTTP"
  vpc_id      = module.networking.vpc_id
  target_type = "ip"

  health_check {
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

  tags = merge(
    local.context.common_tags,
    {
      Name = "${local.name_prefix}-backend-tg"
    }
  )
}

# Frontend Target Group
resource "aws_lb_target_group" "frontend" {
  name        = "${local.name_prefix}-frontend-tg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = module.networking.vpc_id
  target_type = "ip"

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
  }

  deregistration_delay = 30

  tags = merge(
    local.context.common_tags,
    {
      Name = "${local.name_prefix}-frontend-tg"
    }
  )
}

# Adminer Target Group
resource "aws_lb_target_group" "adminer" {
  name        = "${local.name_prefix}-adminer-tg"
  port        = 8080
  protocol    = "HTTP"
  vpc_id      = module.networking.vpc_id
  target_type = "ip"

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
  }

  deregistration_delay = 30

  tags = merge(
    local.context.common_tags,
    {
      Name = "${local.name_prefix}-adminer-tg"
    }
  )
}

# HTTP Listener - Redirect to HTTPS
resource "aws_lb_listener" "http" {
  load_balancer_arn = module.load_balancer.alb_arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }

  tags = local.context.common_tags
}

# HTTPS Listener
resource "aws_lb_listener" "https" {
  load_balancer_arn = module.load_balancer.alb_arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = module.acm.certificate_arn

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "Not Found"
      status_code  = "404"
    }
  }

  tags = local.context.common_tags
}

# Backend API Routing (api.domain.com)
resource "aws_lb_listener_rule" "backend" {
  listener_arn = aws_lb_listener.https.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.backend.arn
  }

  condition {
    host_header {
      values = ["api.${var.domain}"]
    }
  }

  tags = local.context.common_tags
}

# Frontend Dashboard Routing (dashboard.domain.com)
resource "aws_lb_listener_rule" "frontend" {
  listener_arn = aws_lb_listener.https.arn
  priority     = 200

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.frontend.arn
  }

  condition {
    host_header {
      values = ["dashboard.${var.domain}"]
    }
  }

  tags = local.context.common_tags
}

# Adminer Routing (adminer.domain.com)
resource "aws_lb_listener_rule" "adminer" {
  listener_arn = aws_lb_listener.https.arn
  priority     = 300

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.adminer.arn
  }

  condition {
    host_header {
      values = ["adminer.${var.domain}"]
    }
  }

  tags = local.context.common_tags
}
