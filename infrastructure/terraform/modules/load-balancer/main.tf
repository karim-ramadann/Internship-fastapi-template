# Application Load Balancer using terraform-aws-modules/alb
module "alb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "~> 9.0"

  name               = "${var.context.project}-${var.context.environment}-alb"
  load_balancer_type = "application"
  internal           = false

  vpc_id          = var.vpc_id
  subnets         = var.public_subnet_ids
  security_groups = [var.alb_security_group_id]

  # Enable deletion protection for production
  enable_deletion_protection = var.context.environment == "production"

  # Access logs (optional but recommended)
  enable_http2               = true
  enable_cross_zone_load_balancing = true

  tags = merge(
    var.context.common_tags,
    {
      Name = "${var.context.project}-${var.context.environment}-alb"
    }
  )
}

# Target Group for Backend (FastAPI)
resource "aws_lb_target_group" "backend" {
  name        = "${var.context.project}-${var.context.environment}-backend-tg"
  port        = 8000
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
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
    var.context.common_tags,
    {
      Name = "${var.context.project}-${var.context.environment}-backend-tg"
    }
  )
}

# Target Group for Frontend
resource "aws_lb_target_group" "frontend" {
  name        = "${var.context.project}-${var.context.environment}-frontend-tg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
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
    var.context.common_tags,
    {
      Name = "${var.context.project}-${var.context.environment}-frontend-tg"
    }
  )
}

# Target Group for Adminer
resource "aws_lb_target_group" "adminer" {
  name        = "${var.context.project}-${var.context.environment}-adminer-tg"
  port        = 8080
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
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
    var.context.common_tags,
    {
      Name = "${var.context.project}-${var.context.environment}-adminer-tg"
    }
  )
}

# HTTP Listener (redirect to HTTPS)
resource "aws_lb_listener" "http" {
  load_balancer_arn = module.alb.arn
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

  tags = var.context.common_tags
}

# HTTPS Listener
resource "aws_lb_listener" "https" {
  load_balancer_arn = module.alb.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = var.certificate_arn

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "Not Found"
      status_code  = "404"
    }
  }

  tags = var.context.common_tags
}

# Listener Rule for Backend (api.domain.com)
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

  tags = var.context.common_tags
}

# Listener Rule for Frontend (dashboard.domain.com)
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

  tags = var.context.common_tags
}

# Listener Rule for Adminer (adminer.domain.com)
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

  tags = var.context.common_tags
}
