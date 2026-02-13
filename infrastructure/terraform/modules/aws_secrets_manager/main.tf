/**
 * # Secrets Manager Module
 *
 * Thin wrapper for AWS Secrets Manager using native Terraform resources.
 *
 * Standards enforced:
 * - Naming convention: `{environment}/{project}/{name}`
 * - Standard tagging with project, environment, and component
 * - Optional KMS encryption
 * - Automatic recovery window based on environment
 */

locals {
  secret_name = "${var.context.environment}/${var.context.project}/${var.name}"

  tags = merge(
    var.context.common_tags,
    {
      Name      = "${var.context.project}-${var.name}-${var.context.environment}"
      Component = "secrets-manager"
    },
    var.tags
  )
}

resource "aws_secretsmanager_secret" "this" {
  name        = local.secret_name
  description = var.description != "" ? var.description : "Secret for ${var.context.project} ${var.context.environment}"

  kms_key_id = var.kms_key_id

  # Shorter recovery window for non-production to allow faster cleanup
  recovery_window_in_days = var.context.environment == "production" ? 30 : 7

  tags = local.tags
}

resource "aws_secretsmanager_secret_version" "this" {
  count = var.secret_string != null ? 1 : 0

  secret_id     = aws_secretsmanager_secret.this.id
  secret_string = var.secret_string
}

resource "aws_secretsmanager_secret_rotation" "this" {
  count = var.rotation_lambda_arn != null ? 1 : 0

  secret_id           = aws_secretsmanager_secret.this.id
  rotation_lambda_arn = var.rotation_lambda_arn

  rotation_rules {
    automatically_after_days = var.rotation_days
  }
}
