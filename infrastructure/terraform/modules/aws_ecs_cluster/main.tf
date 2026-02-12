/**
 * # AWS ECS Cluster Module
 *
 * Thin wrapper around [terraform-aws-modules/ecs/aws](https://registry.terraform.io/modules/terraform-aws-modules/ecs/aws/latest).
 *
 * This module provides organization-wide standards for ECS clusters:
 * - Fargate and/or EC2 capacity providers
 * - Container Insights enabled by default
 * - CloudWatch logging configuration
 * - Execute command configuration for debugging
 * - Service Connect defaults
 * - IAM roles for infrastructure and instances
 * - Standard naming and tagging conventions
 */

locals {
  # Naming standard: project-resource-name-env (flat)
  cluster_name = "${var.context.project}-${var.name}-${var.context.environment}"
  
  tags = merge(
    var.context.common_tags,
    {
      Name      = local.cluster_name
      Component = "ecs-cluster"
    },
    var.tags
  )
}

module "ecs_cluster" {
  source  = "terraform-aws-modules/ecs/aws"
  version = "~> 7.3"

  cluster_name = local.cluster_name

  # Cluster configuration
  cluster_configuration = var.cluster_configuration

  # Cluster settings (Container Insights, etc.)
  cluster_setting = var.cluster_setting

  # Service Connect defaults
  cluster_service_connect_defaults = var.cluster_service_connect_defaults

  # Capacity providers
  cluster_capacity_providers       = var.cluster_capacity_providers
  default_capacity_provider_strategy = var.default_capacity_provider_strategy
  capacity_providers                = var.capacity_providers

  # CloudWatch logging
  create_cloudwatch_log_group              = var.create_cloudwatch_log_group
  cloudwatch_log_group_name                = var.cloudwatch_log_group_name
  cloudwatch_log_group_retention_in_days   = var.cloudwatch_log_group_retention_in_days
  cloudwatch_log_group_kms_key_id          = var.cloudwatch_log_group_kms_key_id
  cloudwatch_log_group_class               = var.cloudwatch_log_group_class
  cloudwatch_log_group_tags                = merge(local.tags, var.cloudwatch_log_group_tags)

  # IAM roles
  create_infrastructure_iam_role                   = var.create_infrastructure_iam_role
  infrastructure_iam_role_name                     = var.infrastructure_iam_role_name
  infrastructure_iam_role_use_name_prefix          = var.infrastructure_iam_role_use_name_prefix
  infrastructure_iam_role_path                     = var.infrastructure_iam_role_path
  infrastructure_iam_role_description              = var.infrastructure_iam_role_description
  infrastructure_iam_role_permissions_boundary     = var.infrastructure_iam_role_permissions_boundary
  infrastructure_iam_role_statements               = var.infrastructure_iam_role_statements
  infrastructure_iam_role_tags                     = merge(local.tags, var.infrastructure_iam_role_tags)

  create_node_iam_instance_profile                 = var.create_node_iam_instance_profile
  node_iam_role_name                               = var.node_iam_role_name
  node_iam_role_use_name_prefix                    = var.node_iam_role_use_name_prefix
  node_iam_role_path                               = var.node_iam_role_path
  node_iam_role_description                        = var.node_iam_role_description
  node_iam_role_permissions_boundary               = var.node_iam_role_permissions_boundary
  node_iam_role_additional_policies                = var.node_iam_role_additional_policies
  node_iam_role_statements                         = var.node_iam_role_statements
  node_iam_role_tags                               = merge(local.tags, var.node_iam_role_tags)

  create_task_exec_iam_role                        = var.create_task_exec_iam_role
  create_task_exec_policy                          = var.create_task_exec_policy

  cluster_tags = merge(local.tags, var.cluster_tags)

  tags = local.tags
}
