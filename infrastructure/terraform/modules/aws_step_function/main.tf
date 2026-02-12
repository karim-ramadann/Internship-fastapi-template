/**
 * # AWS Step Functions Module
 *
 * Thin wrapper around [terraform-aws-modules/step-functions/aws](https://registry.terraform.io/modules/terraform-aws-modules/step-functions/aws/latest).
 *
 * This module provides organization-wide standards for AWS Step Functions:
 * - Standard naming and tagging conventions
 * - IAM role with service integrations (Lambda, SQS, ECS, Batch, DynamoDB, etc.)
 * - CloudWatch Logs integration for execution history
 * - Support for STANDARD and EXPRESS state machine types
 * - Encryption configuration for data at rest
 */

locals {
  state_machine_name = "${var.context.project}-${var.context.environment}-${var.name}"
  
  tags = merge(
    var.context.common_tags,
    {
      Name      = local.state_machine_name
      Component = "step-functions"
    },
    var.tags
  )
}

module "step_function" {
  source  = "terraform-aws-modules/step-functions/aws"
  version = "~> 4.2"

  name       = local.state_machine_name
  definition = var.definition
  type       = var.type
  publish    = var.publish

  # IAM role
  create_role                = var.create_role
  use_existing_role          = var.use_existing_role
  role_arn                   = var.role_arn
  role_name                  = var.role_name != null ? var.role_name : "${local.state_machine_name}-role"
  role_description           = var.role_description
  role_path                  = var.role_path
  role_permissions_boundary  = var.role_permissions_boundary
  role_force_detach_policies = var.role_force_detach_policies
  role_tags                  = merge(local.tags, var.role_tags)

  # Service integrations
  attach_policies_for_integrations = var.attach_policies_for_integrations
  service_integrations             = var.service_integrations

  # Additional IAM policies
  attach_policy            = var.attach_policy
  policy                   = var.policy
  attach_policies          = var.attach_policies
  policies                 = var.policies
  number_of_policies       = var.number_of_policies
  attach_policy_json       = var.attach_policy_json
  policy_json              = var.policy_json
  attach_policy_jsons      = var.attach_policy_jsons
  policy_jsons             = var.policy_jsons
  number_of_policy_jsons   = var.number_of_policy_jsons
  attach_policy_statements = var.attach_policy_statements
  policy_statements        = var.policy_statements
  policy_path              = var.policy_path

  # CloudWatch Logs
  attach_cloudwatch_logs_policy      = var.attach_cloudwatch_logs_policy
  logging_configuration              = var.logging_configuration
  use_existing_cloudwatch_log_group  = var.use_existing_cloudwatch_log_group
  cloudwatch_log_group_name          = var.cloudwatch_log_group_name
  cloudwatch_log_group_retention_in_days = var.cloudwatch_log_group_retention_in_days
  cloudwatch_log_group_kms_key_id    = var.cloudwatch_log_group_kms_key_id
  cloudwatch_log_group_tags          = merge(local.tags, var.cloudwatch_log_group_tags)

  # Encryption configuration
  encryption_configuration = var.encryption_configuration

  # Assume role configuration
  aws_region_assume_role = var.aws_region_assume_role
  trusted_entities       = var.trusted_entities

  # Timeouts
  sfn_state_machine_timeouts = var.sfn_state_machine_timeouts

  tags = local.tags
}
