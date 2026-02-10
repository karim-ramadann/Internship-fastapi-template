/**
 * # Application Load Balancer Module
 *
 * Thin wrapper around [terraform-aws-modules/alb/aws](https://registry.terraform.io/modules/terraform-aws-modules/alb/aws/latest).
 *
 * This module provides organization-wide standards for ALB configuration:
 * - Naming convention: `{project}-{environment}-alb`
 * - Standard tagging with project and environment
 * - HTTP/2 enabled by default
 * - Cross-zone load balancing enabled
 * - Configurable deletion protection
 *
 * **Note**: Target groups, listeners, and listener rules should be defined in the root module
 * to maintain flexibility and avoid coupling business logic to this wrapper.
 */

locals {
  alb_name = "${var.context.project}-${var.context.environment}-alb"
  
  tags = merge(
    var.context.common_tags,
    {
      Name      = local.alb_name
      Component = "load-balancer"
    }
  )
}

module "alb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "~> 9.0"

  name               = local.alb_name
  load_balancer_type = var.load_balancer_type
  internal           = var.internal

  vpc_id          = var.vpc_id
  subnets         = var.subnets
  security_groups = var.security_groups

  # Deletion protection
  enable_deletion_protection = var.enable_deletion_protection

  # Performance settings
  enable_http2                     = var.enable_http2
  enable_cross_zone_load_balancing = var.enable_cross_zone_load_balancing
  
  # Access logs (optional)
  access_logs = var.access_logs

  tags = local.tags
}
