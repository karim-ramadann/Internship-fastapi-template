# ============================================================================
# SSM Parameter Store - Application Secrets
# ============================================================================
# Secrets are stored as SecureString parameters in SSM Parameter Store.
# Naming convention: /{environment}/{project}/{secret_name}
#
# These are managed by Terraform. Override values via terraform.tfvars
# or pass them as variables during apply.
# ============================================================================

variable "secret_key" {
  description = "Application secret key for JWT tokens"
  type        = string
  default     = "staging-secret-key-changeme"
  sensitive   = true
}

variable "first_superuser_password" {
  description = "Password for the first superuser account"
  type        = string
  default     = "changeme"
  sensitive   = true
}

variable "smtp_password" {
  description = "SMTP server password"
  type        = string
  default     = ""
  sensitive   = true
}

resource "aws_ssm_parameter" "secret_key" {
  name  = "/${var.environment}/${var.project}/secret_key"
  type  = "SecureString"
  value = var.secret_key

  tags = local.context.common_tags

  lifecycle {
    ignore_changes = [value]
  }
}

resource "aws_ssm_parameter" "first_superuser_password" {
  name  = "/${var.environment}/${var.project}/first_superuser_password"
  type  = "SecureString"
  value = var.first_superuser_password

  tags = local.context.common_tags

  lifecycle {
    ignore_changes = [value]
  }
}

resource "aws_ssm_parameter" "smtp_password" {
  name  = "/${var.environment}/${var.project}/smtp_password"
  type  = "SecureString"
  value = var.smtp_password

  tags = local.context.common_tags

  lifecycle {
    ignore_changes = [value]
  }
}
