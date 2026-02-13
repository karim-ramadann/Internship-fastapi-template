output "vpc_id" {
  description = "ID of the VPC"
  value       = module.vpc.vpc_id
}

output "vpc_arn" {
  description = "ARN of the VPC"
  value       = module.vpc.vpc_arn
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC"
  value       = module.vpc.vpc_cidr_block
}

output "vpc_main_route_table_id" {
  description = "ID of the main route table associated with this VPC"
  value       = module.vpc.vpc_main_route_table_id
}

output "vpc_default_security_group_id" {
  description = "ID of the default security group"
  value       = module.vpc.default_security_group_id
}

output "vpc_default_network_acl_id" {
  description = "ID of the default network ACL"
  value       = module.vpc.default_network_acl_id
}

output "vpc_owner_id" {
  description = "Owner ID of the VPC"
  value       = module.vpc.vpc_owner_id
}

# Subnets
output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = module.vpc.public_subnets
}

output "public_subnet_arns" {
  description = "ARNs of the public subnets"
  value       = module.vpc.public_subnet_arns
}

output "public_subnet_cidr_blocks" {
  description = "CIDR blocks of the public subnets"
  value       = module.vpc.public_subnets_cidr_blocks
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = module.vpc.private_subnets
}

output "private_subnet_arns" {
  description = "ARNs of the private subnets"
  value       = module.vpc.private_subnet_arns
}

output "private_subnet_cidr_blocks" {
  description = "CIDR blocks of the private subnets"
  value       = module.vpc.private_subnets_cidr_blocks
}

output "database_subnet_ids" {
  description = "IDs of the database subnets"
  value       = module.vpc.database_subnets
}

output "database_subnet_arns" {
  description = "ARNs of the database subnets"
  value       = module.vpc.database_subnet_arns
}

output "database_subnet_group_name" {
  description = "Name of database subnet group"
  value       = module.vpc.database_subnet_group_name
}

output "elasticache_subnet_ids" {
  description = "IDs of the elasticache subnets"
  value       = module.vpc.elasticache_subnets
}

output "elasticache_subnet_arns" {
  description = "ARNs of the elasticache subnets"
  value       = module.vpc.elasticache_subnet_arns
}

output "elasticache_subnet_group_name" {
  description = "Name of elasticache subnet group"
  value       = module.vpc.elasticache_subnet_group_name
}

output "redshift_subnet_ids" {
  description = "IDs of the redshift subnets"
  value       = module.vpc.redshift_subnets
}

output "redshift_subnet_arns" {
  description = "ARNs of the redshift subnets"
  value       = module.vpc.redshift_subnet_arns
}

output "redshift_subnet_group_name" {
  description = "Name of redshift subnet group"
  value       = module.vpc.redshift_subnet_group
}

output "intra_subnet_ids" {
  description = "IDs of the intra subnets"
  value       = module.vpc.intra_subnets
}

output "intra_subnet_arns" {
  description = "ARNs of the intra subnets"
  value       = module.vpc.intra_subnet_arns
}

# Route Tables
output "public_route_table_ids" {
  description = "IDs of the public route tables"
  value       = module.vpc.public_route_table_ids
}

output "private_route_table_ids" {
  description = "IDs of the private route tables"
  value       = module.vpc.private_route_table_ids
}

output "database_route_table_ids" {
  description = "IDs of the database route tables"
  value       = module.vpc.database_route_table_ids
}

output "elasticache_route_table_ids" {
  description = "IDs of the elasticache route tables"
  value       = module.vpc.elasticache_route_table_ids
}

output "redshift_route_table_ids" {
  description = "IDs of the redshift route tables"
  value       = module.vpc.redshift_route_table_ids
}

output "intra_route_table_ids" {
  description = "IDs of the intra route tables"
  value       = module.vpc.intra_route_table_ids
}

# NAT Gateway
output "nat_gateway_ids" {
  description = "IDs of the NAT Gateways"
  value       = module.vpc.natgw_ids
}

output "nat_gateway_public_ips" {
  description = "Public IPs of the NAT Gateways"
  value       = module.vpc.nat_public_ips
}

# Internet Gateway
output "internet_gateway_id" {
  description = "ID of the Internet Gateway"
  value       = module.vpc.igw_id
}

output "internet_gateway_arn" {
  description = "ARN of the Internet Gateway"
  value       = module.vpc.igw_arn
}

# VPN Gateway
output "vpn_gateway_id" {
  description = "ID of the VPN Gateway"
  value       = module.vpc.vgw_id
}

output "vpn_gateway_arn" {
  description = "ARN of the VPN Gateway"
  value       = module.vpc.vgw_arn
}

# Customer Gateway
output "customer_gateway_ids" {
  description = "IDs of the Customer Gateways"
  value       = module.vpc.cgw_ids
}

output "customer_gateway_arns" {
  description = "ARNs of the Customer Gateways"
  value       = module.vpc.cgw_arns
}

# DHCP Options
output "dhcp_options_id" {
  description = "ID of the DHCP options"
  value       = module.vpc.dhcp_options_id
}

# VPC Flow Logs
output "vpc_flow_log_id" {
  description = "ID of the VPC Flow Log"
  value       = module.vpc.vpc_flow_log_id
}

output "vpc_flow_log_cloudwatch_log_group_arn" {
  description = "ARN of the CloudWatch Log Group for VPC Flow Logs"
  value       = try(module.vpc.vpc_flow_log_cloudwatch_log_group_arn, null)
}

# Availability Zones
output "availability_zones" {
  description = "List of availability zones used"
  value       = module.vpc.azs
}
