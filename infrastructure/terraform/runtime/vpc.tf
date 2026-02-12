# ============================================================================
# VPC and Networking Resources
# ============================================================================

module "vpc" {
  source = "../modules/aws_vpc"

  context = local.context

  # VPC Configuration
  vpc_cidr           = var.vpc_cidr
  availability_zones = local.availability_zones

  # Subnet Configuration
  public_subnet_cidrs   = local.public_subnet_cidrs
  private_subnet_cidrs  = local.private_subnet_cidrs
  database_subnet_cidrs = local.database_subnet_cidrs

  # Database subnet group
  create_database_subnet_group       = true
  create_database_subnet_route_table = true
  create_database_nat_gateway_route  = false

  # NAT Gateway Configuration
  enable_nat_gateway     = true
  single_nat_gateway     = var.single_nat_gateway
  one_nat_gateway_per_az = var.one_nat_gateway_per_az

  # Internet Gateway
  create_igw = true

  # DNS Settings
  enable_dns_hostnames = true
  enable_dns_support   = true

  # VPC Endpoints for ECS (optional but recommended)
  enable_ecr_api_endpoint = true
  enable_ecr_dkr_endpoint = true
  enable_logs_endpoint    = true
  enable_s3_endpoint      = true

  ecr_api_endpoint_private_dns_enabled = true
  ecr_dkr_endpoint_private_dns_enabled = true
  logs_endpoint_private_dns_enabled    = true

  tags = {
    Component = "networking"
  }
}
