/**
 * # Networking Module
 *
 * Thin wrapper around [terraform-aws-modules/vpc/aws](https://registry.terraform.io/modules/terraform-aws-modules/vpc/aws/latest).
 *
 * This module provides organization-wide standards for VPC configuration including:
 * - Consistent naming convention: `{project}-{environment}-vpc`
 * - Standard tagging with project, environment, and tier tags
 * - DNS resolution enabled by default
 * - Configurable NAT gateway strategy (single vs per-AZ)
 */

locals {
  vpc_name = "${var.context.project}-${var.context.environment}-vpc"
  
  tags = merge(
    var.context.common_tags,
    {
      Name      = local.vpc_name
      Component = "networking"
    }
  )
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = local.vpc_name
  cidr = var.vpc_cidr

  azs             = var.availability_zones
  private_subnets = var.private_subnet_cidrs
  public_subnets  = var.public_subnet_cidrs

  # NAT Gateway configuration (passed from root)
  enable_nat_gateway     = var.enable_nat_gateway
  single_nat_gateway     = var.single_nat_gateway
  one_nat_gateway_per_az = var.one_nat_gateway_per_az

  # DNS settings
  enable_dns_hostnames = var.enable_dns_hostnames
  enable_dns_support   = var.enable_dns_support

  # Tags
  tags = local.tags

  public_subnet_tags = merge(
    {
      Tier = "Public"
      Name = "${local.vpc_name}-public"
    },
    var.public_subnet_tags
  )

  private_subnet_tags = merge(
    {
      Tier = "Private"
      Name = "${local.vpc_name}-private"
    },
    var.private_subnet_tags
  )
}
