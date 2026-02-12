# SSM Parameters for ECS Task Secrets and Configuration

# Auto-generated secrets
resource "random_password" "secret_key" {
  length  = 64
  special = true
}

resource "random_password" "first_superuser_password" {
  length  = 32
  special = true
}

# Application Secrets (SecureString)
resource "aws_ssm_parameter" "secret_key" {
  name  = "/${var.environment}/${var.project}/SECRET_KEY"
  type  = "SecureString"
  value = random_password.secret_key.result
  tags  = local.context.common_tags

  lifecycle {
    ignore_changes = [value]
  }
}

resource "aws_ssm_parameter" "first_superuser_password" {
  name  = "/${var.environment}/${var.project}/FIRST_SUPERUSER_PASSWORD"
  type  = "SecureString"
  value = random_password.first_superuser_password.result
  tags  = local.context.common_tags

  lifecycle {
    ignore_changes = [value]
  }
}

resource "aws_ssm_parameter" "postgres_password" {
  name  = "/${var.environment}/${var.project}/POSTGRES_PASSWORD"
  type  = "SecureString"
  value = module.database.db_password
  tags  = local.context.common_tags
}

# SMTP Configuration (optional - only created if values are provided)
resource "aws_ssm_parameter" "smtp_host" {
  count = var.smtp_host != "" ? 1 : 0
  name  = "/${var.environment}/${var.project}/SMTP_HOST"
  type  = "String"
  value = var.smtp_host
  tags  = local.context.common_tags
}

resource "aws_ssm_parameter" "smtp_user" {
  count = var.smtp_user != "" ? 1 : 0
  name  = "/${var.environment}/${var.project}/SMTP_USER"
  type  = "String"
  value = var.smtp_user
  tags  = local.context.common_tags
}

resource "aws_ssm_parameter" "smtp_password" {
  count = var.smtp_password != "" ? 1 : 0
  name  = "/${var.environment}/${var.project}/SMTP_PASSWORD"
  type  = "SecureString"
  value = var.smtp_password
  tags  = local.context.common_tags
}

# Sentry Configuration (optional)
resource "aws_ssm_parameter" "sentry_dsn" {
  count = var.sentry_dsn != "" ? 1 : 0
  name  = "/${var.environment}/${var.project}/SENTRY_DSN"
  type  = "String"
  value = var.sentry_dsn
  tags  = local.context.common_tags
}
