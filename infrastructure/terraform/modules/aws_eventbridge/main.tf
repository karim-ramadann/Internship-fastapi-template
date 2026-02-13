/**
 * # AWS EventBridge Module
 *
 * Thin wrapper around [terraform-aws-modules/eventbridge/aws](https://registry.terraform.io/modules/terraform-aws-modules/eventbridge/aws/latest).
 *
 * This module provides organization-wide standards for AWS EventBridge:
 * - Custom event buses with logging configuration
 * - Event rules with pattern matching
 * - Event targets (Lambda, SQS, SNS, Step Functions, ECS, Kinesis, etc.)
 * - IAM roles with service-specific policies
 * - Event archives and replays
 * - Event permissions for cross-account access
 * - API destinations and connections
 * - EventBridge Scheduler
 * - Standard naming and tagging conventions
 */

locals {
  bus_name = var.bus_name != null ? "${var.context.project}-${var.context.environment}-${var.bus_name}" : "default"

  tags = merge(
    var.context.common_tags,
    {
      Component = "eventbridge"
    },
    var.tags
  )
}

module "eventbridge" {
  source  = "terraform-aws-modules/eventbridge/aws"
  version = "~> 4.3"

  create     = var.create
  bus_name   = local.bus_name
  create_bus = var.create_bus

  # Bus configuration
  bus_description    = var.bus_description
  event_source_name  = var.event_source_name
  kms_key_identifier = var.kms_key_identifier

  # Logging configuration
  log_config   = var.log_config
  log_delivery = var.log_delivery

  # Rules
  create_rules = var.create_rules
  rules        = var.rules

  # Targets
  create_targets = var.create_targets
  targets        = var.targets

  # Archives
  create_archives = var.create_archives
  archives        = var.archives

  # Permissions
  create_permissions = var.create_permissions
  permissions        = var.permissions

  # Connections and API Destinations
  create_connections      = var.create_connections
  connections             = var.connections
  create_api_destinations = var.create_api_destinations
  api_destinations        = var.api_destinations

  # Schedules
  create_schedule_groups = var.create_schedule_groups
  schedule_groups        = var.schedule_groups
  create_schedules       = var.create_schedules
  schedules              = var.schedules

  # Pipes
  create_pipes = var.create_pipes
  pipes        = var.pipes

  # Schema discovery
  create_schemas_discoverer = var.create_schemas_discoverer

  # IAM role
  create_role = var.create_role

  # Service integration policies
  attach_cloudwatch_policy       = var.attach_cloudwatch_policy
  cloudwatch_target_arns         = var.cloudwatch_target_arns
  attach_ecs_policy              = var.attach_ecs_policy
  ecs_target_arns                = var.ecs_target_arns
  ecs_pass_role_resources        = var.ecs_pass_role_resources
  attach_kinesis_policy          = var.attach_kinesis_policy
  kinesis_target_arns            = var.kinesis_target_arns
  attach_kinesis_firehose_policy = var.attach_kinesis_firehose_policy
  kinesis_firehose_target_arns   = var.kinesis_firehose_target_arns
  attach_lambda_policy           = var.attach_lambda_policy
  lambda_target_arns             = var.lambda_target_arns
  attach_sfn_policy              = var.attach_sfn_policy
  sfn_target_arns                = var.sfn_target_arns
  attach_sqs_policy              = var.attach_sqs_policy
  sqs_target_arns                = var.sqs_target_arns
  attach_sns_policy              = var.attach_sns_policy
  sns_target_arns                = var.sns_target_arns
  attach_api_destination_policy  = var.attach_api_destination_policy
  attach_tracing_policy          = var.attach_tracing_policy

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

  # Naming postfixes
  append_rule_postfix           = var.append_rule_postfix
  append_connection_postfix     = var.append_connection_postfix
  append_destination_postfix    = var.append_destination_postfix
  append_schedule_postfix       = var.append_schedule_postfix
  append_schedule_group_postfix = var.append_schedule_group_postfix
  append_pipe_postfix           = var.append_pipe_postfix

  tags = local.tags
}
