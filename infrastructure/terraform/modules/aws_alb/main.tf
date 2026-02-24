/**
 * # AWS Application Load Balancer Module
 *
 * Thin wrapper around [terraform-aws-modules/alb/aws](https://registry.terraform.io/modules/terraform-aws-modules/alb/aws/latest).
 *
 * This module provides organization-wide standards for Application Load Balancers:
 * - HTTP and HTTPS listener configuration
 * - Target group management with health checks
 * - Access logging to S3 (optional)
 * - WAF integration (optional)
 * - Cross-zone load balancing
 * - Connection draining configuration
 * - Standard naming and tagging conventions
 */

locals {
  # Naming standard: project-resource-name-env (flat)
  alb_name = "${var.context.project}-${var.name}-${var.context.environment}"

  tags = merge(
    var.context.common_tags,
    {
      Name      = local.alb_name
      Component = "load-balancer"
    },
    var.tags
  )
}

module "alb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "~> 10.0"

  name               = local.alb_name
  load_balancer_type = var.load_balancer_type
  internal           = var.internal

  # Networking
  vpc_id                     = var.vpc_id
  subnets                    = var.subnets
  security_groups            = var.security_groups
  enable_deletion_protection = var.enable_deletion_protection

  # Cross-zone load balancing
  enable_cross_zone_load_balancing = var.enable_cross_zone_load_balancing

  # HTTP/2 and HTTP/3
  enable_http2               = var.enable_http2
  enable_waf_fail_open       = var.enable_waf_fail_open
  enable_xff_client_port     = var.enable_xff_client_port
  preserve_host_header       = var.preserve_host_header
  xff_header_processing_mode = var.xff_header_processing_mode
  desync_mitigation_mode     = var.desync_mitigation_mode
  drop_invalid_header_fields = var.drop_invalid_header_fields
  idle_timeout               = var.idle_timeout
  ip_address_type            = var.ip_address_type

  # Access logs
  access_logs = var.access_logs

  # Connection logs
  connection_logs = var.connection_logs

  # Target groups
  target_groups = var.target_groups

  # Listeners
  listeners = var.listeners

  # Route53 alias
  route53_records = var.route53_records

  # WAF
  web_acl_arn = var.web_acl_arn

  # Tags
  tags = local.tags
}
