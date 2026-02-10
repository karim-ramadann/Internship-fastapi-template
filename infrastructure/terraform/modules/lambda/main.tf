/**
 * # Lambda Function Module
 *
 * Thin wrapper around [terraform-aws-modules/lambda/aws](https://registry.terraform.io/modules/terraform-aws-modules/lambda/aws/latest).
 *
 * This module provides organization-wide standards for Lambda functions:
 * - Naming convention: `{project}-{environment}-{function_name}`
 * - Standard tagging with project, environment, and component
 * - Environment-based log retention (prod=30 days, others=7 days)
 * - VPC integration by default for private subnet execution
 * - Automatic network policy attachment when VPC subnets are provided
 */

locals {
  function_name = "${var.context.project}-${var.context.environment}-${var.function_name}"
  
  # Org-wide log retention standard
  log_retention = var.cloudwatch_logs_retention_in_days != null ? var.cloudwatch_logs_retention_in_days : (
    var.context.environment == "production" ? 30 : 7
  )
  
  tags = merge(
    var.context.common_tags,
    {
      Name      = local.function_name
      Component = "lambda"
    },
    var.tags
  )
}

module "lambda_function" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "~> 7.0"
  
  # Pass through terraform-aws-modules/lambda inputs
  function_name = local.function_name
  description   = var.description
  handler       = var.handler
  runtime       = var.runtime
  timeout       = var.timeout
  memory_size   = var.memory_size
  
  # IAM
  create_role = false
  lambda_role = var.lambda_role
  
  # VPC configuration
  vpc_subnet_ids         = var.vpc_subnet_ids
  vpc_security_group_ids = var.vpc_security_group_ids
  attach_network_policy  = length(var.vpc_subnet_ids) > 0
  
  # Environment variables
  environment_variables = var.environment_variables
  
  # CloudWatch Logs (org standard)
  cloudwatch_logs_retention_in_days = local.log_retention
  
  # Package configuration
  create_package         = var.create_package
  local_existing_package = var.local_existing_package
  image_uri              = var.image_uri
  package_type           = var.package_type
  
  # Additional IAM policies
  attach_policy_statements = var.attach_policy_statements
  policy_statements        = var.policy_statements
  
  tags = local.tags
}
