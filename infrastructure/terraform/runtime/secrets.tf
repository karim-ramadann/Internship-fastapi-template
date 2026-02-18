# ============================================================================
# AWS Secrets Manager - Application Secrets
# ============================================================================
# Store application secrets in AWS Secrets Manager for secure access by ECS tasks.
# Values are sourced from SSM Parameter Store SecureString parameters.
# Database credentials are managed by the database module.
# ============================================================================

module "app_secrets" {
  source = "../modules/aws_secrets_manager"

  context = local.context
  name    = "app/secrets"

  description = "Application secrets for ${var.project} ${var.environment}"

  secret_string = jsonencode({
    secret_key               = random_password.secret_key.result
    first_superuser_password = random_password.first_superuser_password.result
    smtp_password            = "placeholder"
  })
}
