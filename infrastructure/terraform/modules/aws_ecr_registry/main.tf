/**
 * # ECR Registry Configuration Module
 *
 * Thin wrapper around [terraform-aws-modules/ecr/aws](https://registry.terraform.io/modules/terraform-aws-modules/ecr/aws/latest).
 *
 * This module manages AWS ECR registry-level settings (not individual repositories):
 * - Registry scanning configuration (ENHANCED or BASIC)
 * - Cross-region and cross-account replication rules
 * - Registry policy for permissions
 * - Pull-through cache rules for upstream registries (Docker Hub, ECR Public, etc.)
 *
 * Note: ECR Registry is a regional resource with one registry per AWS account per region.
 */

module "ecr" {
  source  = "terraform-aws-modules/ecr/aws"
  version = "~> 3.0"

  # Disable repository creation - this module is for registry-level config only
  create_repository = false

  # Registry Policy
  create_registry_policy = var.create_registry_policy
  registry_policy        = var.registry_policy

  # Registry Pull Through Cache Rules
  registry_pull_through_cache_rules = var.pull_through_cache_rules

  # Registry Scanning Configuration
  manage_registry_scanning_configuration = var.manage_registry_scanning_configuration
  registry_scan_type                     = var.registry_scan_type
  registry_scan_rules                    = var.registry_scan_rules

  # Registry Replication Configuration
  create_registry_replication_configuration = var.create_registry_replication_configuration
  registry_replication_rules                = var.registry_replication_rules

  tags = var.context.common_tags
}
