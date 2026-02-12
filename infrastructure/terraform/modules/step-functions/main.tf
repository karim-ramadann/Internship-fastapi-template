/**
 * # Step Functions State Machine Module
 *
 * Thin wrapper around [terraform-aws-modules/step-functions/aws](https://registry.terraform.io/modules/terraform-aws-modules/step-functions/aws/latest).
 *
 * This module provides organization-wide standards for Step Functions:
 * - Naming convention: `{project}-{environment}-{state_machine_name}`
 * - Standard tagging with project, environment, and component
 * - Environment-based log retention (prod=30 days, others=7 days)
 * - CloudWatch Logs integration with structured logging
 * - Configurable execution data inclusion for non-production environments
 */

locals {
  state_machine_name = "${var.context.project}-${var.context.environment}-${var.state_machine_name}"
  
  log_retention = var.cloudwatch_logs_retention_in_days != null ? var.cloudwatch_logs_retention_in_days : (
    var.context.environment == "production" ? 30 : 7
  )
  
  tags = merge(
    var.context.common_tags,
    {
      Name      = local.state_machine_name
      Component = "step-functions"
    },
    var.tags
  )
}

# CloudWatch Log Group for Step Functions execution logs
resource "aws_cloudwatch_log_group" "step_functions" {
  name              = "${var.context.environment}/step-functions/${local.state_machine_name}"
  retention_in_days = local.log_retention
  
  tags = local.tags
}

module "step_function" {
  source  = "terraform-aws-modules/step-functions/aws"
  version = "~> 4.0"
  
  # Pass through terraform-aws-modules/step-functions inputs
  name       = local.state_machine_name
  definition = var.definition
  type       = var.type
  
  # IAM
  create_role = false
  role_arn    = var.role_arn
  
  # CloudWatch Logs configuration
  logging_configuration = {
    level                  = var.log_level
    include_execution_data = var.include_execution_data
    log_destination        = "${aws_cloudwatch_log_group.step_functions.arn}:*"
  }
  
  tags = local.tags
}
