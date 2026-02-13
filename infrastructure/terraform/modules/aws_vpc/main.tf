/**
 * # VPC Module
 *
 * Thin wrapper around [terraform-aws-modules/vpc/aws](https://registry.terraform.io/modules/terraform-aws-modules/vpc/aws/latest).
 *
 * ## Simple Default Architecture
 * 
 * By default, creates a simple 2-tier VPC with:
 * - 2 public subnets (10.0.1.0/24, 10.0.2.0/24)
 * - 2 private subnets (10.0.10.0/24, 10.0.11.0/24)
 * - Single NAT Gateway (cost-effective for dev/staging)
 * - Internet Gateway for public subnets
 * - DNS hostnames and support enabled
 * 
 * Available when needed:
 * - Additional subnet tiers (database, elasticache, redshift, intra)
 * - VPC Flow Logs for network monitoring and security
 * - VPC Endpoints (S3, DynamoDB, ECR, ECS, etc.) for cost optimization
 * - Per-AZ NAT Gateways for production high availability
 * - IPv6 support
 * - VPN Gateway for hybrid connectivity
 * - Custom DHCP options
 * - Default security group management
 */

locals {
  # Naming standard: project-resource-name-env (flat)
  vpc_name = "${var.context.project}-vpc-${var.context.environment}"

  tags = merge(
    var.context.common_tags,
    {
      Name      = local.vpc_name
      Component = "networking"
    },
    var.tags
  )
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 6.0"

  name = local.vpc_name
  cidr = var.vpc_cidr

  # IPv6
  enable_ipv6 = var.enable_ipv6

  # Availability Zones and Subnets
  azs                 = var.availability_zones
  private_subnets     = var.private_subnet_cidrs
  public_subnets      = var.public_subnet_cidrs
  database_subnets    = var.database_subnet_cidrs
  elasticache_subnets = var.elasticache_subnet_cidrs
  redshift_subnets    = var.redshift_subnet_cidrs
  intra_subnets       = var.intra_subnet_cidrs

  # Database subnet group
  create_database_subnet_group           = var.create_database_subnet_group
  create_database_subnet_route_table     = var.create_database_subnet_route_table
  create_database_internet_gateway_route = var.create_database_internet_gateway_route
  create_database_nat_gateway_route      = var.create_database_nat_gateway_route

  # ElastiCache subnet group
  create_elasticache_subnet_group       = var.create_elasticache_subnet_group
  create_elasticache_subnet_route_table = var.create_elasticache_subnet_route_table

  # Redshift subnet group
  create_redshift_subnet_group       = var.create_redshift_subnet_group
  create_redshift_subnet_route_table = var.create_redshift_subnet_route_table

  # NAT Gateway configuration
  enable_nat_gateway     = var.enable_nat_gateway
  single_nat_gateway     = var.single_nat_gateway
  one_nat_gateway_per_az = var.one_nat_gateway_per_az
  reuse_nat_ips          = var.reuse_nat_ips
  external_nat_ip_ids    = var.external_nat_ip_ids

  # Internet Gateway
  create_igw = var.create_igw

  # DNS settings
  enable_dns_hostnames = var.enable_dns_hostnames
  enable_dns_support   = var.enable_dns_support

  # DHCP Options
  enable_dhcp_options               = var.enable_dhcp_options
  dhcp_options_domain_name          = var.dhcp_options_domain_name
  dhcp_options_domain_name_servers  = var.dhcp_options_domain_name_servers
  dhcp_options_ntp_servers          = var.dhcp_options_ntp_servers
  dhcp_options_netbios_name_servers = var.dhcp_options_netbios_name_servers
  dhcp_options_netbios_node_type    = var.dhcp_options_netbios_node_type

  # VPC Flow Logs
  enable_flow_log                                 = var.enable_flow_log
  create_flow_log_cloudwatch_iam_role             = var.create_flow_log_cloudwatch_iam_role
  create_flow_log_cloudwatch_log_group            = var.create_flow_log_cloudwatch_log_group
  flow_log_destination_type                       = var.flow_log_destination_type
  flow_log_destination_arn                        = var.flow_log_destination_arn
  flow_log_cloudwatch_log_group_name_prefix       = var.flow_log_cloudwatch_log_group_name_prefix
  flow_log_cloudwatch_log_group_retention_in_days = var.flow_log_cloudwatch_log_group_retention_in_days
  flow_log_cloudwatch_log_group_kms_key_id        = var.flow_log_cloudwatch_log_group_kms_key_id
  flow_log_max_aggregation_interval               = var.flow_log_max_aggregation_interval
  flow_log_traffic_type                           = var.flow_log_traffic_type
  flow_log_log_format                             = var.flow_log_log_format
  flow_log_file_format                            = var.flow_log_file_format
  flow_log_hive_compatible_partitions             = var.flow_log_hive_compatible_partitions
  flow_log_per_hour_partition                     = var.flow_log_per_hour_partition

  # VPN Gateway
  enable_vpn_gateway = var.enable_vpn_gateway
  vpn_gateway_id     = var.vpn_gateway_id
  vpn_gateway_az     = var.vpn_gateway_az

  # Customer Gateway
  customer_gateways = var.customer_gateways

  # Default Security Group
  manage_default_security_group  = var.manage_default_security_group
  default_security_group_name    = var.default_security_group_name
  default_security_group_ingress = var.default_security_group_ingress
  default_security_group_egress  = var.default_security_group_egress

  # Default Network ACL
  manage_default_network_acl  = var.manage_default_network_acl
  default_network_acl_name    = var.default_network_acl_name
  default_network_acl_ingress = var.default_network_acl_ingress
  default_network_acl_egress  = var.default_network_acl_egress

  # Default Route Table
  manage_default_route_table           = var.manage_default_route_table
  default_route_table_name             = var.default_route_table_name
  default_route_table_propagating_vgws = var.default_route_table_propagating_vgws
  default_route_table_routes           = var.default_route_table_routes

  # Tags
  tags = local.tags

  vpc_tags         = var.vpc_tags
  igw_tags         = var.igw_tags
  nat_gateway_tags = var.nat_gateway_tags
  nat_eip_tags     = var.nat_eip_tags

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

  database_subnet_tags = merge(
    {
      Tier = "Database"
      Name = "${local.vpc_name}-database"
    },
    var.database_subnet_tags
  )

  elasticache_subnet_tags = merge(
    {
      Tier = "ElastiCache"
      Name = "${local.vpc_name}-elasticache"
    },
    var.elasticache_subnet_tags
  )

  redshift_subnet_tags = merge(
    {
      Tier = "Redshift"
      Name = "${local.vpc_name}-redshift"
    },
    var.redshift_subnet_tags
  )

  intra_subnet_tags = merge(
    {
      Tier = "Intra"
      Name = "${local.vpc_name}-intra"
    },
    var.intra_subnet_tags
  )

  public_route_table_tags      = var.public_route_table_tags
  private_route_table_tags     = var.private_route_table_tags
  database_route_table_tags    = var.database_route_table_tags
  elasticache_route_table_tags = var.elasticache_route_table_tags
  redshift_route_table_tags    = var.redshift_route_table_tags
  intra_route_table_tags       = var.intra_route_table_tags

  dhcp_options_tags = var.dhcp_options_tags
  vpn_gateway_tags  = var.vpn_gateway_tags
}
