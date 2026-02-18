/**
 * # SSM Parameter Module
 *
 * Thin wrapper for AWS SSM Parameter Store using native Terraform resources.
 *
 * Standards enforced:
 * - Naming convention: `/{environment}/{project}/{name}`
 * - Standard tagging with project, environment, and component
 * - SecureString type by default
 * - Lifecycle ignore on value so Terraform won't overwrite manual changes
 */

locals {
  parameter_name = "/${var.context.environment}/${var.context.project}/${var.name}"

  tags = merge(
    var.context.common_tags,
    {
      Name      = "${var.context.project}-${var.name}-${var.context.environment}"
      Component = "ssm-parameter"
    },
    var.tags
  )
}

resource "aws_ssm_parameter" "this" {
  name  = local.parameter_name
  type  = var.type
  value = var.value

  description = var.description != "" ? var.description : "Parameter for ${var.context.project} ${var.context.environment}"

  key_id = var.type == "SecureString" ? var.kms_key_id : null

  tags = local.tags

  lifecycle {
    ignore_changes = [value]
  }
}
