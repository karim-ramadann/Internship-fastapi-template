/**
 * # AWS Security Group Module
 *
 * Thin wrapper around [terraform-aws-modules/security-group/aws](https://registry.terraform.io/modules/terraform-aws-modules/security-group/aws/latest).
 *
 * This module provides organization-wide standards for security groups:
 * - Simplified ingress and egress rule definitions
 * - Support for CIDR blocks, security groups, and prefix lists
 * - Automatic security group rule creation
 * - Computed rules for dynamic configurations
 * - Standard naming and tagging conventions
 */

locals {
  # Naming standard: project-resource-name-env (flat)
  security_group_name = "${var.context.project}-${var.name}-${var.context.environment}"

  tags = merge(
    var.context.common_tags,
    {
      Name      = local.security_group_name
      Component = "security"
    },
    var.tags
  )
}

module "security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 5.0"

  name        = local.security_group_name
  description = var.description
  vpc_id      = var.vpc_id

  # Ingress rules with CIDR blocks
  ingress_with_cidr_blocks = var.ingress_with_cidr_blocks

  # Ingress rules with source security groups
  ingress_with_source_security_group_id = var.ingress_with_source_security_group_id

  # Ingress rules with self
  ingress_with_self = var.ingress_with_self

  # Computed ingress rules
  computed_ingress_with_cidr_blocks                        = var.computed_ingress_with_cidr_blocks
  computed_ingress_with_source_security_group_id           = var.computed_ingress_with_source_security_group_id
  computed_ingress_with_self                               = var.computed_ingress_with_self
  number_of_computed_ingress_with_cidr_blocks              = var.number_of_computed_ingress_with_cidr_blocks
  number_of_computed_ingress_with_source_security_group_id = var.number_of_computed_ingress_with_source_security_group_id
  number_of_computed_ingress_with_self                     = var.number_of_computed_ingress_with_self

  # Egress rules with CIDR blocks
  egress_with_cidr_blocks = var.egress_with_cidr_blocks

  # Egress rules with source security groups
  egress_with_source_security_group_id = var.egress_with_source_security_group_id

  # Egress rules with self
  egress_with_self = var.egress_with_self

  # Computed egress rules
  computed_egress_with_cidr_blocks                        = var.computed_egress_with_cidr_blocks
  computed_egress_with_source_security_group_id           = var.computed_egress_with_source_security_group_id
  computed_egress_with_self                               = var.computed_egress_with_self
  number_of_computed_egress_with_cidr_blocks              = var.number_of_computed_egress_with_cidr_blocks
  number_of_computed_egress_with_source_security_group_id = var.number_of_computed_egress_with_source_security_group_id
  number_of_computed_egress_with_self                     = var.number_of_computed_egress_with_self

  # Ingress rules (simple)
  ingress_rules            = var.ingress_rules
  ingress_cidr_blocks      = var.ingress_cidr_blocks
  ingress_ipv6_cidr_blocks = var.ingress_ipv6_cidr_blocks
  ingress_prefix_list_ids  = var.ingress_prefix_list_ids

  # Egress rules (simple)
  egress_rules            = var.egress_rules
  egress_cidr_blocks      = var.egress_cidr_blocks
  egress_ipv6_cidr_blocks = var.egress_ipv6_cidr_blocks
  egress_prefix_list_ids  = var.egress_prefix_list_ids

  # Auto-assign rules
  auto_groups = var.auto_groups

  # Use name prefix
  use_name_prefix = var.use_name_prefix

  # Create security group
  create = var.create

  # Revoke rules on delete
  revoke_rules_on_delete = var.revoke_rules_on_delete

  tags = local.tags
}
