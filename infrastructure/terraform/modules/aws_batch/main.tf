/**
 * # AWS Batch Module
 *
 * Thin wrapper around [terraform-aws-modules/batch/aws](https://registry.terraform.io/modules/terraform-aws-modules/batch/aws/latest).
 *
 * This module provides organization-wide standards for AWS Batch:
 * - Compute environments (EC2, EC2 Spot, Fargate, Fargate Spot)
 * - Job queues with priority and scheduling policies
 * - Job definitions for containerized batch workloads
 * - IAM roles for service, instance, and spot fleet
 * - Standard naming and tagging conventions
 */

locals {
  name_prefix = "${var.context.project}-${var.context.environment}"

  tags = merge(
    var.context.common_tags,
    {
      Component = "batch"
    },
    var.tags
  )
}

module "batch" {
  source  = "terraform-aws-modules/batch/aws"
  version = "~> 3.0"

  # Compute environments
  compute_environments = var.compute_environments

  # Job queues
  create_job_queues = var.create_job_queues
  job_queues        = var.job_queues

  # Job definitions
  job_definitions = var.job_definitions

  # IAM roles
  create_instance_iam_role               = var.create_instance_iam_role
  instance_iam_role_name                 = var.instance_iam_role_name != null ? var.instance_iam_role_name : "${local.name_prefix}-batch-instance"
  instance_iam_role_use_name_prefix      = var.instance_iam_role_use_name_prefix
  instance_iam_role_path                 = var.instance_iam_role_path
  instance_iam_role_description          = var.instance_iam_role_description
  instance_iam_role_permissions_boundary = var.instance_iam_role_permissions_boundary
  instance_iam_role_additional_policies  = var.instance_iam_role_additional_policies
  instance_iam_role_tags                 = merge(local.tags, var.instance_iam_role_tags)

  create_service_iam_role               = var.create_service_iam_role
  service_iam_role_name                 = var.service_iam_role_name != null ? var.service_iam_role_name : "${local.name_prefix}-batch-service"
  service_iam_role_use_name_prefix      = var.service_iam_role_use_name_prefix
  service_iam_role_path                 = var.service_iam_role_path
  service_iam_role_description          = var.service_iam_role_description
  service_iam_role_permissions_boundary = var.service_iam_role_permissions_boundary
  service_iam_role_additional_policies  = var.service_iam_role_additional_policies
  service_iam_role_tags                 = merge(local.tags, var.service_iam_role_tags)

  create_spot_fleet_iam_role               = var.create_spot_fleet_iam_role
  spot_fleet_iam_role_name                 = var.spot_fleet_iam_role_name != null ? var.spot_fleet_iam_role_name : "${local.name_prefix}-batch-spot-fleet"
  spot_fleet_iam_role_use_name_prefix      = var.spot_fleet_iam_role_use_name_prefix
  spot_fleet_iam_role_path                 = var.spot_fleet_iam_role_path
  spot_fleet_iam_role_description          = var.spot_fleet_iam_role_description
  spot_fleet_iam_role_permissions_boundary = var.spot_fleet_iam_role_permissions_boundary
  spot_fleet_iam_role_additional_policies  = var.spot_fleet_iam_role_additional_policies
  spot_fleet_iam_role_tags                 = merge(local.tags, var.spot_fleet_iam_role_tags)

  tags = local.tags
}
