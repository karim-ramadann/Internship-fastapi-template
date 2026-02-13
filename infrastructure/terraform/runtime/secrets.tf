# ============================================================================
# AWS Secrets Manager - Application Secrets
# ============================================================================
# Store application secrets in AWS Secrets Manager for secure access by ECS tasks.
# Values are sourced from SSM Parameter Store SecureString parameters.
# Database credentials are managed by the database module.
# ============================================================================

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
    secret_key               = aws_ssm_parameter.secret_key.value
    first_superuser_password = aws_ssm_parameter.first_superuser_password.value
    smtp_password            = aws_ssm_parameter.smtp_password.value
  })
}
