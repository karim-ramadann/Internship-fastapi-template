# Staging Environment Configuration
# Based on values from .env file

# AWS Configuration
aws_region  = "us-east-1"  # TODO: Update to your preferred region
environment = "staging"
project     = "full-stack-fastapi-project"

# Domain Configuration
# TODO: Update these with your actual staging domain
domain        = "staging.example.com"
frontend_host = "https://dashboard.staging.example.com"

# Route53 Configuration
# Set to true to create a new hosted zone, false to use existing
# If creating new zone, you'll need to update NS records at your domain registrar
create_hosted_zone = false  # Set to true if you don't have a hosted zone yet

# Backend Configuration
# IMPORTANT: Replace these with secure values from GitHub Secrets
secret_key                 = "changethis"  # TODO: Generate with: python -c "import secrets; print(secrets.token_urlsafe(32))"
first_superuser           = "admin@example.com"
first_superuser_password  = "changethis"   # TODO: Generate secure password
backend_cors_origins      = "https://dashboard.staging.example.com,https://api.staging.example.com"

# SMTP Configuration (optional - leave empty if not using email)
smtp_host         = ""
smtp_user         = ""
smtp_password     = ""
emails_from_email = "info@example.com"
smtp_tls          = true
smtp_ssl          = false
smtp_port         = 587

# Sentry Configuration (optional)
sentry_dsn = ""

# Database Configuration
db_name     = "app"
db_username = "postgres"

# Infrastructure Sizing (Staging: smaller/cheaper resources)
vpc_cidr               = "10.0.0.0/16"
ec2_instance_type      = "t3.small"
ecs_desired_count      = 1
rds_instance_class     = "db.t3.micro"
rds_allocated_storage  = 20
rds_multi_az           = false  # Single AZ for cost savings in staging
rds_backup_retention_days = 1   # Shorter retention for staging

# Docker Image Tags (defaults to "latest", overridden by CI/CD)
backend_image_tag  = "latest"
frontend_image_tag = "latest"

# Common Tags
common_tags = {
  Environment = "staging"
  Project     = "full-stack-fastapi-project"
  ManagedBy   = "terraform"
  Owner       = "DevOps"
}
