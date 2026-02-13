<!-- BEGIN_TF_DOCS -->
# VPC Module

Thin wrapper around [terraform-aws-modules/vpc/aws](https://registry.terraform.io/modules/terraform-aws-modules/vpc/aws/latest).

## Simple Default Architecture

By default, creates a simple 2-tier VPC with:
- 2 public subnets (10.0.1.0/24, 10.0.2.0/24)
- 2 private subnets (10.0.10.0/24, 10.0.11.0/24)
- Single NAT Gateway (cost-effective for dev/staging)
- Internet Gateway for public subnets
- DNS hostnames and support enabled

Available when needed:
- Additional subnet tiers (database, elasticache, redshift, intra)
- VPC Flow Logs for network monitoring and security
- VPC Endpoints (S3, DynamoDB, ECR, ECS, etc.) for cost optimization
- Per-AZ NAT Gateways for production high availability
- IPv6 support
- VPN Gateway for hybrid connectivity
- Custom DHCP options
- Default security group management

## Usage

```hcl
module "example" {
  source = "../modules/this-module"
  
  context = {
    project     = "my-project"
    environment = "dev"
    region      = "us-east-1"
    common_tags = {
      Environment = "dev"
      ManagedBy   = "terraform"
    }
  }
  
  # Add required variables here
}
```

## Requirements

No requirements.

## Providers

No providers.

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_vpc"></a> [vpc](#module\_vpc) | terraform-aws-modules/vpc/aws | ~> 5.0 |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_availability_zones"></a> [availability\_zones](#input\_availability\_zones) | List of availability zones for subnet placement | `list(string)` | n/a | yes |
| <a name="input_context"></a> [context](#input\_context) | Context object containing project, environment, region, and common tags | <pre>object({<br/>    project     = string<br/>    environment = string<br/>    region      = string<br/>    common_tags = map(string)<br/>  })</pre> | n/a | yes |
| <a name="input_assign_ipv6_address_on_creation"></a> [assign\_ipv6\_address\_on\_creation](#input\_assign\_ipv6\_address\_on\_creation) | Specify true to indicate that network interfaces created in the specified subnet should be assigned an IPv6 address | `bool` | `false` | no |
| <a name="input_create_database_internet_gateway_route"></a> [create\_database\_internet\_gateway\_route](#input\_create\_database\_internet\_gateway\_route) | Controls if an internet gateway route for public database access should be created | `bool` | `false` | no |
| <a name="input_create_database_nat_gateway_route"></a> [create\_database\_nat\_gateway\_route](#input\_create\_database\_nat\_gateway\_route) | Controls if a NAT gateway route should be created to give internet access to the database subnets | `bool` | `false` | no |
| <a name="input_create_database_subnet_group"></a> [create\_database\_subnet\_group](#input\_create\_database\_subnet\_group) | Controls if database subnet group should be created (n.b. database\_subnets must also be set) | `bool` | `false` | no |
| <a name="input_create_database_subnet_route_table"></a> [create\_database\_subnet\_route\_table](#input\_create\_database\_subnet\_route\_table) | Controls if separate route table for database should be created | `bool` | `false` | no |
| <a name="input_create_elasticache_subnet_group"></a> [create\_elasticache\_subnet\_group](#input\_create\_elasticache\_subnet\_group) | Controls if elasticache subnet group should be created | `bool` | `false` | no |
| <a name="input_create_elasticache_subnet_route_table"></a> [create\_elasticache\_subnet\_route\_table](#input\_create\_elasticache\_subnet\_route\_table) | Controls if separate route table for elasticache should be created | `bool` | `false` | no |
| <a name="input_create_flow_log_cloudwatch_iam_role"></a> [create\_flow\_log\_cloudwatch\_iam\_role](#input\_create\_flow\_log\_cloudwatch\_iam\_role) | Whether to create IAM role for VPC Flow Logs | `bool` | `false` | no |
| <a name="input_create_flow_log_cloudwatch_log_group"></a> [create\_flow\_log\_cloudwatch\_log\_group](#input\_create\_flow\_log\_cloudwatch\_log\_group) | Whether to create CloudWatch log group for VPC Flow Logs | `bool` | `false` | no |
| <a name="input_create_igw"></a> [create\_igw](#input\_create\_igw) | Controls if an Internet Gateway is created for public subnets | `bool` | `true` | no |
| <a name="input_create_redshift_subnet_group"></a> [create\_redshift\_subnet\_group](#input\_create\_redshift\_subnet\_group) | Controls if redshift subnet group should be created | `bool` | `false` | no |
| <a name="input_create_redshift_subnet_route_table"></a> [create\_redshift\_subnet\_route\_table](#input\_create\_redshift\_subnet\_route\_table) | Controls if separate route table for redshift should be created | `bool` | `false` | no |
| <a name="input_customer_gateways"></a> [customer\_gateways](#input\_customer\_gateways) | Maps of Customer Gateway's attributes (BGP ASN and Gateway's Internet-routable external IP address) | `map(map(any))` | `{}` | no |
| <a name="input_database_route_table_tags"></a> [database\_route\_table\_tags](#input\_database\_route\_table\_tags) | Additional tags for the database route tables | `map(string)` | `{}` | no |
| <a name="input_database_subnet_cidrs"></a> [database\_subnet\_cidrs](#input\_database\_subnet\_cidrs) | List of CIDR blocks for database subnets | `list(string)` | `[]` | no |
| <a name="input_database_subnet_tags"></a> [database\_subnet\_tags](#input\_database\_subnet\_tags) | Additional tags for database subnets | `map(string)` | `{}` | no |
| <a name="input_default_network_acl_egress"></a> [default\_network\_acl\_egress](#input\_default\_network\_acl\_egress) | List of maps of egress rules to set on the Default Network ACL | `list(map(string))` | `[]` | no |
| <a name="input_default_network_acl_ingress"></a> [default\_network\_acl\_ingress](#input\_default\_network\_acl\_ingress) | List of maps of ingress rules to set on the Default Network ACL | `list(map(string))` | `[]` | no |
| <a name="input_default_network_acl_name"></a> [default\_network\_acl\_name](#input\_default\_network\_acl\_name) | Name to be used on the Default Network ACL | `string` | `null` | no |
| <a name="input_default_route_table_name"></a> [default\_route\_table\_name](#input\_default\_route\_table\_name) | Name to be used on the default route table | `string` | `null` | no |
| <a name="input_default_route_table_propagating_vgws"></a> [default\_route\_table\_propagating\_vgws](#input\_default\_route\_table\_propagating\_vgws) | List of virtual gateways for propagation | `list(string)` | `[]` | no |
| <a name="input_default_route_table_routes"></a> [default\_route\_table\_routes](#input\_default\_route\_table\_routes) | Configuration block of routes | `list(map(string))` | `[]` | no |
| <a name="input_default_security_group_egress"></a> [default\_security\_group\_egress](#input\_default\_security\_group\_egress) | List of maps of egress rules to set on the default security group | `list(map(string))` | `[]` | no |
| <a name="input_default_security_group_ingress"></a> [default\_security\_group\_ingress](#input\_default\_security\_group\_ingress) | List of maps of ingress rules to set on the default security group | `list(map(string))` | `[]` | no |
| <a name="input_default_security_group_name"></a> [default\_security\_group\_name](#input\_default\_security\_group\_name) | Name to be used on the default security group | `string` | `null` | no |
| <a name="input_dhcp_options_domain_name"></a> [dhcp\_options\_domain\_name](#input\_dhcp\_options\_domain\_name) | Specifies DNS name for DHCP options set (requires enable\_dhcp\_options set to true) | `string` | `""` | no |
| <a name="input_dhcp_options_domain_name_servers"></a> [dhcp\_options\_domain\_name\_servers](#input\_dhcp\_options\_domain\_name\_servers) | Specify a list of DNS server addresses for DHCP options set, default to AWS provided (requires enable\_dhcp\_options set to true) | `list(string)` | <pre>[<br/>  "AmazonProvidedDNS"<br/>]</pre> | no |
| <a name="input_dhcp_options_netbios_name_servers"></a> [dhcp\_options\_netbios\_name\_servers](#input\_dhcp\_options\_netbios\_name\_servers) | Specify a list of netbios servers for DHCP options set (requires enable\_dhcp\_options set to true) | `list(string)` | `[]` | no |
| <a name="input_dhcp_options_netbios_node_type"></a> [dhcp\_options\_netbios\_node\_type](#input\_dhcp\_options\_netbios\_node\_type) | Specify netbios node\_type for DHCP options set (requires enable\_dhcp\_options set to true) | `string` | `""` | no |
| <a name="input_dhcp_options_ntp_servers"></a> [dhcp\_options\_ntp\_servers](#input\_dhcp\_options\_ntp\_servers) | Specify a list of NTP servers for DHCP options set (requires enable\_dhcp\_options set to true) | `list(string)` | `[]` | no |
| <a name="input_dhcp_options_tags"></a> [dhcp\_options\_tags](#input\_dhcp\_options\_tags) | Additional tags for the DHCP option set | `map(string)` | `{}` | no |
| <a name="input_ec2messages_endpoint_private_dns_enabled"></a> [ec2messages\_endpoint\_private\_dns\_enabled](#input\_ec2messages\_endpoint\_private\_dns\_enabled) | Whether or not to associate a private hosted zone with the specified VPC for EC2 Messages endpoint | `bool` | `true` | no |
| <a name="input_ec2messages_endpoint_security_group_ids"></a> [ec2messages\_endpoint\_security\_group\_ids](#input\_ec2messages\_endpoint\_security\_group\_ids) | The ID of one or more security groups to associate with the network interface for EC2 Messages endpoint | `list(string)` | `[]` | no |
| <a name="input_ec2messages_endpoint_subnet_ids"></a> [ec2messages\_endpoint\_subnet\_ids](#input\_ec2messages\_endpoint\_subnet\_ids) | The ID of one or more subnets in which to create a network interface for EC2 Messages endpoint | `list(string)` | `[]` | no |
| <a name="input_ecr_api_endpoint_private_dns_enabled"></a> [ecr\_api\_endpoint\_private\_dns\_enabled](#input\_ecr\_api\_endpoint\_private\_dns\_enabled) | Whether or not to associate a private hosted zone with the specified VPC for ECR API endpoint | `bool` | `true` | no |
| <a name="input_ecr_api_endpoint_security_group_ids"></a> [ecr\_api\_endpoint\_security\_group\_ids](#input\_ecr\_api\_endpoint\_security\_group\_ids) | The ID of one or more security groups to associate with the network interface for ECR API endpoint | `list(string)` | `[]` | no |
| <a name="input_ecr_api_endpoint_subnet_ids"></a> [ecr\_api\_endpoint\_subnet\_ids](#input\_ecr\_api\_endpoint\_subnet\_ids) | The ID of one or more subnets in which to create a network interface for ECR API endpoint | `list(string)` | `[]` | no |
| <a name="input_ecr_dkr_endpoint_private_dns_enabled"></a> [ecr\_dkr\_endpoint\_private\_dns\_enabled](#input\_ecr\_dkr\_endpoint\_private\_dns\_enabled) | Whether or not to associate a private hosted zone with the specified VPC for ECR DKR endpoint | `bool` | `true` | no |
| <a name="input_ecr_dkr_endpoint_security_group_ids"></a> [ecr\_dkr\_endpoint\_security\_group\_ids](#input\_ecr\_dkr\_endpoint\_security\_group\_ids) | The ID of one or more security groups to associate with the network interface for ECR DKR endpoint | `list(string)` | `[]` | no |
| <a name="input_ecr_dkr_endpoint_subnet_ids"></a> [ecr\_dkr\_endpoint\_subnet\_ids](#input\_ecr\_dkr\_endpoint\_subnet\_ids) | The ID of one or more subnets in which to create a network interface for ECR DKR endpoint | `list(string)` | `[]` | no |
| <a name="input_ecs_agent_endpoint_private_dns_enabled"></a> [ecs\_agent\_endpoint\_private\_dns\_enabled](#input\_ecs\_agent\_endpoint\_private\_dns\_enabled) | Whether or not to associate a private hosted zone with the specified VPC for ECS Agent endpoint | `bool` | `true` | no |
| <a name="input_ecs_agent_endpoint_security_group_ids"></a> [ecs\_agent\_endpoint\_security\_group\_ids](#input\_ecs\_agent\_endpoint\_security\_group\_ids) | The ID of one or more security groups to associate with the network interface for ECS Agent endpoint | `list(string)` | `[]` | no |
| <a name="input_ecs_agent_endpoint_subnet_ids"></a> [ecs\_agent\_endpoint\_subnet\_ids](#input\_ecs\_agent\_endpoint\_subnet\_ids) | The ID of one or more subnets in which to create a network interface for ECS Agent endpoint | `list(string)` | `[]` | no |
| <a name="input_ecs_endpoint_private_dns_enabled"></a> [ecs\_endpoint\_private\_dns\_enabled](#input\_ecs\_endpoint\_private\_dns\_enabled) | Whether or not to associate a private hosted zone with the specified VPC for ECS endpoint | `bool` | `true` | no |
| <a name="input_ecs_endpoint_security_group_ids"></a> [ecs\_endpoint\_security\_group\_ids](#input\_ecs\_endpoint\_security\_group\_ids) | The ID of one or more security groups to associate with the network interface for ECS endpoint | `list(string)` | `[]` | no |
| <a name="input_ecs_endpoint_subnet_ids"></a> [ecs\_endpoint\_subnet\_ids](#input\_ecs\_endpoint\_subnet\_ids) | The ID of one or more subnets in which to create a network interface for ECS endpoint | `list(string)` | `[]` | no |
| <a name="input_ecs_telemetry_endpoint_private_dns_enabled"></a> [ecs\_telemetry\_endpoint\_private\_dns\_enabled](#input\_ecs\_telemetry\_endpoint\_private\_dns\_enabled) | Whether or not to associate a private hosted zone with the specified VPC for ECS Telemetry endpoint | `bool` | `true` | no |
| <a name="input_ecs_telemetry_endpoint_security_group_ids"></a> [ecs\_telemetry\_endpoint\_security\_group\_ids](#input\_ecs\_telemetry\_endpoint\_security\_group\_ids) | The ID of one or more security groups to associate with the network interface for ECS Telemetry endpoint | `list(string)` | `[]` | no |
| <a name="input_ecs_telemetry_endpoint_subnet_ids"></a> [ecs\_telemetry\_endpoint\_subnet\_ids](#input\_ecs\_telemetry\_endpoint\_subnet\_ids) | The ID of one or more subnets in which to create a network interface for ECS Telemetry endpoint | `list(string)` | `[]` | no |
| <a name="input_elasticache_route_table_tags"></a> [elasticache\_route\_table\_tags](#input\_elasticache\_route\_table\_tags) | Additional tags for the elasticache route tables | `map(string)` | `{}` | no |
| <a name="input_elasticache_subnet_cidrs"></a> [elasticache\_subnet\_cidrs](#input\_elasticache\_subnet\_cidrs) | List of CIDR blocks for elasticache subnets | `list(string)` | `[]` | no |
| <a name="input_elasticache_subnet_tags"></a> [elasticache\_subnet\_tags](#input\_elasticache\_subnet\_tags) | Additional tags for elasticache subnets | `map(string)` | `{}` | no |
| <a name="input_enable_dhcp_options"></a> [enable\_dhcp\_options](#input\_enable\_dhcp\_options) | Should be true if you want to specify a DHCP options set with a custom domain name, DNS servers, NTP servers, netbios servers, and/or netbios server type | `bool` | `false` | no |
| <a name="input_enable_dns_hostnames"></a> [enable\_dns\_hostnames](#input\_enable\_dns\_hostnames) | Enable DNS hostnames in the VPC | `bool` | `true` | no |
| <a name="input_enable_dns_support"></a> [enable\_dns\_support](#input\_enable\_dns\_support) | Enable DNS support in the VPC | `bool` | `true` | no |
| <a name="input_enable_dynamodb_endpoint"></a> [enable\_dynamodb\_endpoint](#input\_enable\_dynamodb\_endpoint) | Should be true if you want to provision a DynamoDB endpoint to the VPC | `bool` | `false` | no |
| <a name="input_enable_ec2messages_endpoint"></a> [enable\_ec2messages\_endpoint](#input\_enable\_ec2messages\_endpoint) | Should be true if you want to provision an EC2 Messages endpoint to the VPC | `bool` | `false` | no |
| <a name="input_enable_ecr_api_endpoint"></a> [enable\_ecr\_api\_endpoint](#input\_enable\_ecr\_api\_endpoint) | Should be true if you want to provision an ECR API endpoint to the VPC | `bool` | `false` | no |
| <a name="input_enable_ecr_dkr_endpoint"></a> [enable\_ecr\_dkr\_endpoint](#input\_enable\_ecr\_dkr\_endpoint) | Should be true if you want to provision an ECR DKR endpoint to the VPC | `bool` | `false` | no |
| <a name="input_enable_ecs_agent_endpoint"></a> [enable\_ecs\_agent\_endpoint](#input\_enable\_ecs\_agent\_endpoint) | Should be true if you want to provision an ECS Agent endpoint to the VPC | `bool` | `false` | no |
| <a name="input_enable_ecs_endpoint"></a> [enable\_ecs\_endpoint](#input\_enable\_ecs\_endpoint) | Should be true if you want to provision an ECS endpoint to the VPC | `bool` | `false` | no |
| <a name="input_enable_ecs_telemetry_endpoint"></a> [enable\_ecs\_telemetry\_endpoint](#input\_enable\_ecs\_telemetry\_endpoint) | Should be true if you want to provision an ECS Telemetry endpoint to the VPC | `bool` | `false` | no |
| <a name="input_enable_flow_log"></a> [enable\_flow\_log](#input\_enable\_flow\_log) | Whether or not to enable VPC Flow Logs | `bool` | `false` | no |
| <a name="input_enable_ipv6"></a> [enable\_ipv6](#input\_enable\_ipv6) | Requests an Amazon-provided IPv6 CIDR block with a /56 prefix length for the VPC | `bool` | `false` | no |
| <a name="input_enable_logs_endpoint"></a> [enable\_logs\_endpoint](#input\_enable\_logs\_endpoint) | Should be true if you want to provision a CloudWatch Logs endpoint to the VPC | `bool` | `false` | no |
| <a name="input_enable_nat_gateway"></a> [enable\_nat\_gateway](#input\_enable\_nat\_gateway) | Enable NAT Gateway for private subnet internet access | `bool` | `true` | no |
| <a name="input_enable_s3_endpoint"></a> [enable\_s3\_endpoint](#input\_enable\_s3\_endpoint) | Should be true if you want to provision an S3 endpoint to the VPC | `bool` | `false` | no |
| <a name="input_enable_secretsmanager_endpoint"></a> [enable\_secretsmanager\_endpoint](#input\_enable\_secretsmanager\_endpoint) | Should be true if you want to provision a Secrets Manager endpoint to the VPC | `bool` | `false` | no |
| <a name="input_enable_ssm_endpoint"></a> [enable\_ssm\_endpoint](#input\_enable\_ssm\_endpoint) | Should be true if you want to provision an SSM endpoint to the VPC | `bool` | `false` | no |
| <a name="input_enable_ssmmessages_endpoint"></a> [enable\_ssmmessages\_endpoint](#input\_enable\_ssmmessages\_endpoint) | Should be true if you want to provision an SSM Messages endpoint to the VPC | `bool` | `false` | no |
| <a name="input_enable_vpn_gateway"></a> [enable\_vpn\_gateway](#input\_enable\_vpn\_gateway) | Should be true if you want to create a new VPN Gateway resource and attach it to the VPC | `bool` | `false` | no |
| <a name="input_external_nat_ip_ids"></a> [external\_nat\_ip\_ids](#input\_external\_nat\_ip\_ids) | List of EIP IDs to be assigned to the NAT Gateways (used in combination with reuse\_nat\_ips) | `list(string)` | `[]` | no |
| <a name="input_flow_log_cloudwatch_log_group_kms_key_id"></a> [flow\_log\_cloudwatch\_log\_group\_kms\_key\_id](#input\_flow\_log\_cloudwatch\_log\_group\_kms\_key\_id) | The ARN of the KMS Key to use when encrypting log data for VPC flow logs | `string` | `null` | no |
| <a name="input_flow_log_cloudwatch_log_group_name_prefix"></a> [flow\_log\_cloudwatch\_log\_group\_name\_prefix](#input\_flow\_log\_cloudwatch\_log\_group\_name\_prefix) | Specifies the name prefix of CloudWatch Log Group for VPC flow logs | `string` | `"/aws/vpc-flow-log/"` | no |
| <a name="input_flow_log_cloudwatch_log_group_retention_in_days"></a> [flow\_log\_cloudwatch\_log\_group\_retention\_in\_days](#input\_flow\_log\_cloudwatch\_log\_group\_retention\_in\_days) | Specifies the number of days you want to retain log events in the specified log group for VPC flow logs | `number` | `null` | no |
| <a name="input_flow_log_destination_arn"></a> [flow\_log\_destination\_arn](#input\_flow\_log\_destination\_arn) | ARN of the destination for VPC Flow Logs | `string` | `""` | no |
| <a name="input_flow_log_destination_type"></a> [flow\_log\_destination\_type](#input\_flow\_log\_destination\_type) | Type of flow log destination. Can be cloud-watch-logs or s3 | `string` | `"cloud-watch-logs"` | no |
| <a name="input_flow_log_file_format"></a> [flow\_log\_file\_format](#input\_flow\_log\_file\_format) | The format for the flow log. Valid values: plain-text, parquet | `string` | `null` | no |
| <a name="input_flow_log_hive_compatible_partitions"></a> [flow\_log\_hive\_compatible\_partitions](#input\_flow\_log\_hive\_compatible\_partitions) | Indicates whether to use Hive-compatible prefixes for flow logs stored in Amazon S3 | `bool` | `false` | no |
| <a name="input_flow_log_log_format"></a> [flow\_log\_log\_format](#input\_flow\_log\_log\_format) | The fields to include in the flow log record, in the order in which they should appear | `string` | `null` | no |
| <a name="input_flow_log_max_aggregation_interval"></a> [flow\_log\_max\_aggregation\_interval](#input\_flow\_log\_max\_aggregation\_interval) | The maximum interval of time during which a flow of packets is captured and aggregated into a flow log record. Valid values: 60 seconds or 600 seconds | `number` | `600` | no |
| <a name="input_flow_log_per_hour_partition"></a> [flow\_log\_per\_hour\_partition](#input\_flow\_log\_per\_hour\_partition) | Indicates whether to partition the flow log per hour | `bool` | `false` | no |
| <a name="input_flow_log_traffic_type"></a> [flow\_log\_traffic\_type](#input\_flow\_log\_traffic\_type) | The type of traffic to capture. Valid values: ACCEPT, REJECT, ALL | `string` | `"ALL"` | no |
| <a name="input_igw_tags"></a> [igw\_tags](#input\_igw\_tags) | Additional tags for the internet gateway | `map(string)` | `{}` | no |
| <a name="input_intra_route_table_tags"></a> [intra\_route\_table\_tags](#input\_intra\_route\_table\_tags) | Additional tags for the intra route tables | `map(string)` | `{}` | no |
| <a name="input_intra_subnet_cidrs"></a> [intra\_subnet\_cidrs](#input\_intra\_subnet\_cidrs) | List of CIDR blocks for intra subnets (no internet access) | `list(string)` | `[]` | no |
| <a name="input_intra_subnet_tags"></a> [intra\_subnet\_tags](#input\_intra\_subnet\_tags) | Additional tags for intra subnets | `map(string)` | `{}` | no |
| <a name="input_logs_endpoint_private_dns_enabled"></a> [logs\_endpoint\_private\_dns\_enabled](#input\_logs\_endpoint\_private\_dns\_enabled) | Whether or not to associate a private hosted zone with the specified VPC for CloudWatch Logs endpoint | `bool` | `true` | no |
| <a name="input_logs_endpoint_security_group_ids"></a> [logs\_endpoint\_security\_group\_ids](#input\_logs\_endpoint\_security\_group\_ids) | The ID of one or more security groups to associate with the network interface for CloudWatch Logs endpoint | `list(string)` | `[]` | no |
| <a name="input_logs_endpoint_subnet_ids"></a> [logs\_endpoint\_subnet\_ids](#input\_logs\_endpoint\_subnet\_ids) | The ID of one or more subnets in which to create a network interface for CloudWatch Logs endpoint | `list(string)` | `[]` | no |
| <a name="input_manage_default_network_acl"></a> [manage\_default\_network\_acl](#input\_manage\_default\_network\_acl) | Should be true to adopt and manage Default Network ACL | `bool` | `false` | no |
| <a name="input_manage_default_route_table"></a> [manage\_default\_route\_table](#input\_manage\_default\_route\_table) | Should be true to manage default route table | `bool` | `false` | no |
| <a name="input_manage_default_security_group"></a> [manage\_default\_security\_group](#input\_manage\_default\_security\_group) | Should be true to adopt and manage default security group | `bool` | `true` | no |
| <a name="input_nat_eip_tags"></a> [nat\_eip\_tags](#input\_nat\_eip\_tags) | Additional tags for the NAT EIP | `map(string)` | `{}` | no |
| <a name="input_nat_gateway_tags"></a> [nat\_gateway\_tags](#input\_nat\_gateway\_tags) | Additional tags for the NAT gateways | `map(string)` | `{}` | no |
| <a name="input_one_nat_gateway_per_az"></a> [one\_nat\_gateway\_per\_az](#input\_one\_nat\_gateway\_per\_az) | Create one NAT Gateway per availability zone (recommended for production) | `bool` | `false` | no |
| <a name="input_private_route_table_tags"></a> [private\_route\_table\_tags](#input\_private\_route\_table\_tags) | Additional tags for the private route tables | `map(string)` | `{}` | no |
| <a name="input_private_subnet_cidrs"></a> [private\_subnet\_cidrs](#input\_private\_subnet\_cidrs) | List of CIDR blocks for private subnets | `list(string)` | <pre>[<br/>  "10.0.10.0/24",<br/>  "10.0.11.0/24"<br/>]</pre> | no |
| <a name="input_private_subnet_tags"></a> [private\_subnet\_tags](#input\_private\_subnet\_tags) | Additional tags for private subnets | `map(string)` | `{}` | no |
| <a name="input_public_route_table_tags"></a> [public\_route\_table\_tags](#input\_public\_route\_table\_tags) | Additional tags for the public route tables | `map(string)` | `{}` | no |
| <a name="input_public_subnet_cidrs"></a> [public\_subnet\_cidrs](#input\_public\_subnet\_cidrs) | List of CIDR blocks for public subnets | `list(string)` | <pre>[<br/>  "10.0.1.0/24",<br/>  "10.0.2.0/24"<br/>]</pre> | no |
| <a name="input_public_subnet_tags"></a> [public\_subnet\_tags](#input\_public\_subnet\_tags) | Additional tags for public subnets | `map(string)` | `{}` | no |
| <a name="input_redshift_route_table_tags"></a> [redshift\_route\_table\_tags](#input\_redshift\_route\_table\_tags) | Additional tags for the redshift route tables | `map(string)` | `{}` | no |
| <a name="input_redshift_subnet_cidrs"></a> [redshift\_subnet\_cidrs](#input\_redshift\_subnet\_cidrs) | List of CIDR blocks for redshift subnets | `list(string)` | `[]` | no |
| <a name="input_redshift_subnet_tags"></a> [redshift\_subnet\_tags](#input\_redshift\_subnet\_tags) | Additional tags for redshift subnets | `map(string)` | `{}` | no |
| <a name="input_reuse_nat_ips"></a> [reuse\_nat\_ips](#input\_reuse\_nat\_ips) | Should be true if you don't want EIPs to be created for your NAT Gateways and will instead pass them in via the external\_nat\_ip\_ids variable | `bool` | `false` | no |
| <a name="input_secretsmanager_endpoint_private_dns_enabled"></a> [secretsmanager\_endpoint\_private\_dns\_enabled](#input\_secretsmanager\_endpoint\_private\_dns\_enabled) | Whether or not to associate a private hosted zone with the specified VPC for Secrets Manager endpoint | `bool` | `true` | no |
| <a name="input_secretsmanager_endpoint_security_group_ids"></a> [secretsmanager\_endpoint\_security\_group\_ids](#input\_secretsmanager\_endpoint\_security\_group\_ids) | The ID of one or more security groups to associate with the network interface for Secrets Manager endpoint | `list(string)` | `[]` | no |
| <a name="input_secretsmanager_endpoint_subnet_ids"></a> [secretsmanager\_endpoint\_subnet\_ids](#input\_secretsmanager\_endpoint\_subnet\_ids) | The ID of one or more subnets in which to create a network interface for Secrets Manager endpoint | `list(string)` | `[]` | no |
| <a name="input_single_nat_gateway"></a> [single\_nat\_gateway](#input\_single\_nat\_gateway) | Use a single NAT Gateway for all private subnets (cost-effective for dev/staging, set to false for production) | `bool` | `true` | no |
| <a name="input_ssm_endpoint_private_dns_enabled"></a> [ssm\_endpoint\_private\_dns\_enabled](#input\_ssm\_endpoint\_private\_dns\_enabled) | Whether or not to associate a private hosted zone with the specified VPC for SSM endpoint | `bool` | `true` | no |
| <a name="input_ssm_endpoint_security_group_ids"></a> [ssm\_endpoint\_security\_group\_ids](#input\_ssm\_endpoint\_security\_group\_ids) | The ID of one or more security groups to associate with the network interface for SSM endpoint | `list(string)` | `[]` | no |
| <a name="input_ssm_endpoint_subnet_ids"></a> [ssm\_endpoint\_subnet\_ids](#input\_ssm\_endpoint\_subnet\_ids) | The ID of one or more subnets in which to create a network interface for SSM endpoint | `list(string)` | `[]` | no |
| <a name="input_ssmmessages_endpoint_private_dns_enabled"></a> [ssmmessages\_endpoint\_private\_dns\_enabled](#input\_ssmmessages\_endpoint\_private\_dns\_enabled) | Whether or not to associate a private hosted zone with the specified VPC for SSM Messages endpoint | `bool` | `true` | no |
| <a name="input_ssmmessages_endpoint_security_group_ids"></a> [ssmmessages\_endpoint\_security\_group\_ids](#input\_ssmmessages\_endpoint\_security\_group\_ids) | The ID of one or more security groups to associate with the network interface for SSM Messages endpoint | `list(string)` | `[]` | no |
| <a name="input_ssmmessages_endpoint_subnet_ids"></a> [ssmmessages\_endpoint\_subnet\_ids](#input\_ssmmessages\_endpoint\_subnet\_ids) | The ID of one or more subnets in which to create a network interface for SSM Messages endpoint | `list(string)` | `[]` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Additional tags to merge with common tags | `map(string)` | `{}` | no |
| <a name="input_vpc_cidr"></a> [vpc\_cidr](#input\_vpc\_cidr) | CIDR block for VPC | `string` | `"10.0.0.0/16"` | no |
| <a name="input_vpc_tags"></a> [vpc\_tags](#input\_vpc\_tags) | Additional tags for the VPC | `map(string)` | `{}` | no |
| <a name="input_vpn_gateway_az"></a> [vpn\_gateway\_az](#input\_vpn\_gateway\_az) | The Availability Zone for the VPN Gateway | `string` | `null` | no |
| <a name="input_vpn_gateway_id"></a> [vpn\_gateway\_id](#input\_vpn\_gateway\_id) | ID of VPN Gateway to attach to the VPC | `string` | `""` | no |
| <a name="input_vpn_gateway_tags"></a> [vpn\_gateway\_tags](#input\_vpn\_gateway\_tags) | Additional tags for the VPN gateway | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_availability_zones"></a> [availability\_zones](#output\_availability\_zones) | List of availability zones used |
| <a name="output_customer_gateway_arns"></a> [customer\_gateway\_arns](#output\_customer\_gateway\_arns) | ARNs of the Customer Gateways |
| <a name="output_customer_gateway_ids"></a> [customer\_gateway\_ids](#output\_customer\_gateway\_ids) | IDs of the Customer Gateways |
| <a name="output_database_route_table_ids"></a> [database\_route\_table\_ids](#output\_database\_route\_table\_ids) | IDs of the database route tables |
| <a name="output_database_subnet_arns"></a> [database\_subnet\_arns](#output\_database\_subnet\_arns) | ARNs of the database subnets |
| <a name="output_database_subnet_group_name"></a> [database\_subnet\_group\_name](#output\_database\_subnet\_group\_name) | Name of database subnet group |
| <a name="output_database_subnet_ids"></a> [database\_subnet\_ids](#output\_database\_subnet\_ids) | IDs of the database subnets |
| <a name="output_dhcp_options_id"></a> [dhcp\_options\_id](#output\_dhcp\_options\_id) | ID of the DHCP options |
| <a name="output_elasticache_route_table_ids"></a> [elasticache\_route\_table\_ids](#output\_elasticache\_route\_table\_ids) | IDs of the elasticache route tables |
| <a name="output_elasticache_subnet_arns"></a> [elasticache\_subnet\_arns](#output\_elasticache\_subnet\_arns) | ARNs of the elasticache subnets |
| <a name="output_elasticache_subnet_group_name"></a> [elasticache\_subnet\_group\_name](#output\_elasticache\_subnet\_group\_name) | Name of elasticache subnet group |
| <a name="output_elasticache_subnet_ids"></a> [elasticache\_subnet\_ids](#output\_elasticache\_subnet\_ids) | IDs of the elasticache subnets |
| <a name="output_internet_gateway_arn"></a> [internet\_gateway\_arn](#output\_internet\_gateway\_arn) | ARN of the Internet Gateway |
| <a name="output_internet_gateway_id"></a> [internet\_gateway\_id](#output\_internet\_gateway\_id) | ID of the Internet Gateway |
| <a name="output_intra_route_table_ids"></a> [intra\_route\_table\_ids](#output\_intra\_route\_table\_ids) | IDs of the intra route tables |
| <a name="output_intra_subnet_arns"></a> [intra\_subnet\_arns](#output\_intra\_subnet\_arns) | ARNs of the intra subnets |
| <a name="output_intra_subnet_ids"></a> [intra\_subnet\_ids](#output\_intra\_subnet\_ids) | IDs of the intra subnets |
| <a name="output_nat_gateway_ids"></a> [nat\_gateway\_ids](#output\_nat\_gateway\_ids) | IDs of the NAT Gateways |
| <a name="output_nat_gateway_public_ips"></a> [nat\_gateway\_public\_ips](#output\_nat\_gateway\_public\_ips) | Public IPs of the NAT Gateways |
| <a name="output_private_route_table_ids"></a> [private\_route\_table\_ids](#output\_private\_route\_table\_ids) | IDs of the private route tables |
| <a name="output_private_subnet_arns"></a> [private\_subnet\_arns](#output\_private\_subnet\_arns) | ARNs of the private subnets |
| <a name="output_private_subnet_cidr_blocks"></a> [private\_subnet\_cidr\_blocks](#output\_private\_subnet\_cidr\_blocks) | CIDR blocks of the private subnets |
| <a name="output_private_subnet_ids"></a> [private\_subnet\_ids](#output\_private\_subnet\_ids) | IDs of the private subnets |
| <a name="output_public_route_table_ids"></a> [public\_route\_table\_ids](#output\_public\_route\_table\_ids) | IDs of the public route tables |
| <a name="output_public_subnet_arns"></a> [public\_subnet\_arns](#output\_public\_subnet\_arns) | ARNs of the public subnets |
| <a name="output_public_subnet_cidr_blocks"></a> [public\_subnet\_cidr\_blocks](#output\_public\_subnet\_cidr\_blocks) | CIDR blocks of the public subnets |
| <a name="output_public_subnet_ids"></a> [public\_subnet\_ids](#output\_public\_subnet\_ids) | IDs of the public subnets |
| <a name="output_redshift_route_table_ids"></a> [redshift\_route\_table\_ids](#output\_redshift\_route\_table\_ids) | IDs of the redshift route tables |
| <a name="output_redshift_subnet_arns"></a> [redshift\_subnet\_arns](#output\_redshift\_subnet\_arns) | ARNs of the redshift subnets |
| <a name="output_redshift_subnet_group_name"></a> [redshift\_subnet\_group\_name](#output\_redshift\_subnet\_group\_name) | Name of redshift subnet group |
| <a name="output_redshift_subnet_ids"></a> [redshift\_subnet\_ids](#output\_redshift\_subnet\_ids) | IDs of the redshift subnets |
| <a name="output_vpc_arn"></a> [vpc\_arn](#output\_vpc\_arn) | ARN of the VPC |
| <a name="output_vpc_cidr_block"></a> [vpc\_cidr\_block](#output\_vpc\_cidr\_block) | CIDR block of the VPC |
| <a name="output_vpc_default_network_acl_id"></a> [vpc\_default\_network\_acl\_id](#output\_vpc\_default\_network\_acl\_id) | ID of the default network ACL |
| <a name="output_vpc_default_security_group_id"></a> [vpc\_default\_security\_group\_id](#output\_vpc\_default\_security\_group\_id) | ID of the default security group |
| <a name="output_vpc_endpoint_dynamodb_id"></a> [vpc\_endpoint\_dynamodb\_id](#output\_vpc\_endpoint\_dynamodb\_id) | ID of VPC endpoint for DynamoDB |
| <a name="output_vpc_endpoint_ec2messages_id"></a> [vpc\_endpoint\_ec2messages\_id](#output\_vpc\_endpoint\_ec2messages\_id) | ID of VPC endpoint for EC2 Messages |
| <a name="output_vpc_endpoint_ecr_api_id"></a> [vpc\_endpoint\_ecr\_api\_id](#output\_vpc\_endpoint\_ecr\_api\_id) | ID of VPC endpoint for ECR API |
| <a name="output_vpc_endpoint_ecr_dkr_id"></a> [vpc\_endpoint\_ecr\_dkr\_id](#output\_vpc\_endpoint\_ecr\_dkr\_id) | ID of VPC endpoint for ECR DKR |
| <a name="output_vpc_endpoint_ecs_agent_id"></a> [vpc\_endpoint\_ecs\_agent\_id](#output\_vpc\_endpoint\_ecs\_agent\_id) | ID of VPC endpoint for ECS Agent |
| <a name="output_vpc_endpoint_ecs_id"></a> [vpc\_endpoint\_ecs\_id](#output\_vpc\_endpoint\_ecs\_id) | ID of VPC endpoint for ECS |
| <a name="output_vpc_endpoint_ecs_telemetry_id"></a> [vpc\_endpoint\_ecs\_telemetry\_id](#output\_vpc\_endpoint\_ecs\_telemetry\_id) | ID of VPC endpoint for ECS Telemetry |
| <a name="output_vpc_endpoint_logs_id"></a> [vpc\_endpoint\_logs\_id](#output\_vpc\_endpoint\_logs\_id) | ID of VPC endpoint for CloudWatch Logs |
| <a name="output_vpc_endpoint_s3_id"></a> [vpc\_endpoint\_s3\_id](#output\_vpc\_endpoint\_s3\_id) | ID of VPC endpoint for S3 |
| <a name="output_vpc_endpoint_secretsmanager_id"></a> [vpc\_endpoint\_secretsmanager\_id](#output\_vpc\_endpoint\_secretsmanager\_id) | ID of VPC endpoint for Secrets Manager |
| <a name="output_vpc_endpoint_ssm_id"></a> [vpc\_endpoint\_ssm\_id](#output\_vpc\_endpoint\_ssm\_id) | ID of VPC endpoint for SSM |
| <a name="output_vpc_endpoint_ssmmessages_id"></a> [vpc\_endpoint\_ssmmessages\_id](#output\_vpc\_endpoint\_ssmmessages\_id) | ID of VPC endpoint for SSM Messages |
| <a name="output_vpc_flow_log_cloudwatch_log_group_arn"></a> [vpc\_flow\_log\_cloudwatch\_log\_group\_arn](#output\_vpc\_flow\_log\_cloudwatch\_log\_group\_arn) | ARN of the CloudWatch Log Group for VPC Flow Logs |
| <a name="output_vpc_flow_log_id"></a> [vpc\_flow\_log\_id](#output\_vpc\_flow\_log\_id) | ID of the VPC Flow Log |
| <a name="output_vpc_id"></a> [vpc\_id](#output\_vpc\_id) | ID of the VPC |
| <a name="output_vpc_main_route_table_id"></a> [vpc\_main\_route\_table\_id](#output\_vpc\_main\_route\_table\_id) | ID of the main route table associated with this VPC |
| <a name="output_vpc_owner_id"></a> [vpc\_owner\_id](#output\_vpc\_owner\_id) | Owner ID of the VPC |
| <a name="output_vpn_gateway_arn"></a> [vpn\_gateway\_arn](#output\_vpn\_gateway\_arn) | ARN of the VPN Gateway |
| <a name="output_vpn_gateway_id"></a> [vpn\_gateway\_id](#output\_vpn\_gateway\_id) | ID of the VPN Gateway |
<!-- END_TF_DOCS -->