# ============================================================================
# AWS Secrets Manager - Application Secrets
# ============================================================================
# Store application secrets in AWS Secrets Manager for secure access by ECS tasks.
# Database credentials are managed by the database module.
# ============================================================================

# Application secrets (SECRET_KEY, FIRST_SUPERUSER_PASSWORD, SMTP_PASSWORD)
resource "aws_secretsmanager_secret" "app_secrets" {
  # Naming standard: env/project/service/resource (hierarchical)
  name        = "${var.environment}/${var.project}/app/secrets"
  description = "Application secrets for ${var.project} ${var.environment}"

  tags = merge(
    local.context.common_tags,
    {
      Name      = "${var.project}-app-secrets-${var.environment}"
      Component = "secrets"
    }
  )
}

resource "aws_secretsmanager_secret_version" "app_secrets" {
  secret_id = aws_secretsmanager_secret.app_secrets.id
  secret_string = jsonencode({
    secret_key                = var.secret_key
    first_superuser_password  = var.first_superuser_password
    smtp_password             = var.smtp_password
  })
}
