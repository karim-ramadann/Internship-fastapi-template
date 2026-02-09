# VPC Module using terraform-aws-modules/vpc
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "${var.context.project}-${var.context.environment}-vpc"
  cidr = var.vpc_cidr

  azs             = var.availability_zones
  private_subnets = var.private_subnet_cidrs
  public_subnets  = var.public_subnet_cidrs

  # Enable NAT Gateway for private subnet internet access
  enable_nat_gateway     = true
  single_nat_gateway     = var.context.environment != "production" # Use single NAT for non-prod to save costs
  one_nat_gateway_per_az = var.context.environment == "production" # Use one NAT per AZ in production

  # Enable DNS
  enable_dns_hostnames = true
  enable_dns_support   = true

  # Tags
  tags = merge(
    var.context.common_tags,
    {
      Name = "${var.context.project}-${var.context.environment}-vpc"
    }
  )

  public_subnet_tags = {
    "Tier" = "Public"
    "Name" = "${var.context.project}-${var.context.environment}-public"
  }

  private_subnet_tags = {
    "Tier" = "Private"
    "Name" = "${var.context.project}-${var.context.environment}-private"
  }
}
