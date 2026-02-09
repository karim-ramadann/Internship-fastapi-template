# Production Environment Configuration
# Based on values from .env file

# AWS Configuration
aws_region  = "us-east-1"  # TODO: Update to your preferred region
environment = "production"
project     = "full-stack-fastapi-project"

# Domain Configuration
# TODO: Update these with your actual production domain
domain        = "example.com"
frontend_host = "https://dashboard.example.com"

# Route53 Configuration
# Set to true to create a new hosted zone, false to use existing
# If creating new zone, you'll need to update NS records at your domain registrar
create_hosted_zone = false  # Set to true if you don't have a hosted zone yet

# Backend Configuration
# IMPORTANT: Replace these with secure values from GitHub Secrets
secret_key                 = "changethis"  # TODO: Generate with: python -c "import secrets; print(secrets.token_urlsafe(32))"
first_superuser           = "admin@example.com"
first_superuser_password  = "changethis"   # TODO: Generate secure password
backend_cors_origins      = "https://dashboard.example.com,https://api.example.com"

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

# Infrastructure Sizing (Production: larger/robust resources)
vpc_cidr               = "10.0.0.0/16"
ec2_instance_type      = "t3.medium"
ecs_desired_count      = 1  # Can be increased for high availability
rds_instance_class     = "db.t3.small"
rds_allocated_storage  = 50
rds_multi_az           = true  # Multi-AZ for high availability
rds_backup_retention_days = 7  # 7 days backup retention

# Docker Image Tags (defaults to "latest", overridden by CI/CD)
backend_image_tag  = "latest"
frontend_image_tag = "latest"

# Common Tags
common_tags = {
  Environment = "production"
  Project     = "full-stack-fastapi-project"
  ManagedBy   = "terraform"
  Owner       = "DevOps"
}
