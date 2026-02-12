/**
 * # EventBridge Module
 *
 * Thin wrapper around [terraform-aws-modules/eventbridge/aws](https://registry.terraform.io/modules/terraform-aws-modules/eventbridge/aws/latest).
 *
 * This module provides organization-wide standards for EventBridge:
 * - Naming convention: `{project}-{environment}-{bus_name}` for custom event buses
 * - Standard tagging with project, environment, and component
 * - Support for both default and custom event buses
 * - Flexible rule and target configuration
 *
 * **Note**: Specific event rules and targets should be defined in the root module
 * to maintain flexibility and separation of business logic.
 */

locals {
  bus_name = var.create_bus ? "${var.context.project}-${var.context.environment}-${var.bus_name}" : "default"

  tags = merge(
    var.context.common_tags,
    {
      Component = "eventbridge"
    },
    var.tags
  )
}

# Custom Event Bus (optional)
resource "aws_cloudwatch_event_bus" "this" {
  count = var.create_bus ? 1 : 0

  name = local.bus_name
  tags = local.tags
}

module "eventbridge" {
  source  = "terraform-aws-modules/eventbridge/aws"
  version = "~> 3.0"

  # Use custom bus if created, otherwise default
  create_bus = false
  bus_name   = var.create_bus ? aws_cloudwatch_event_bus.this[0].name : "default"

  # Rules and targets (pass through from root)
  rules   = var.rules
  targets = var.targets

  tags = local.tags
}
