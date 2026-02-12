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

module "load_balancer" {
  source = "./modules/load-balancer"

  context = local.context

  vpc_id          = module.networking.vpc_id
  subnets         = module.networking.public_subnet_ids
  security_groups = [module.security.alb_security_group_id]
  certificate_arn = module.acm.certificate_arn

  enable_deletion_protection = var.environment == "production"

  # Target groups
  target_groups = {
    backend = {
      port              = 8000
      health_check_path = "/api/v1/utils/health-check/"
    }
    frontend = {
      port              = 80
      health_check_path = "/"
    }
    adminer = {
      port              = 8080
      health_check_path = "/"
    }
  }

  # Host-based routing
  host_rules = {
    backend = {
      host             = "api.${var.domain}"
      target_group_key = "backend"
      priority         = 100
    }
    frontend = {
      host             = "dashboard.${var.domain}"
      target_group_key = "frontend"
      priority         = 200
    }
    adminer = {
      host             = "adminer.${var.domain}"
      target_group_key = "adminer"
      priority         = 300
    }
  }
}
