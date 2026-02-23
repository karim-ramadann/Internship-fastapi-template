# ============================================================================
# Development Environment Configuration
# ============================================================================
# This configuration is optimized for cost-effective development and testing.
# Resources use minimal sizing and single-AZ deployment where possible.
# ============================================================================

# Environment Configuration
environment = "dev"
project     = "fastapi"
aws_region  = "eu-west-1"

# Networking Configuration
vpc_cidr               = "10.0.0.0/16"
single_nat_gateway     = true # Cost-effective: single NAT Gateway
one_nat_gateway_per_az = false
public_subnet_cidrs    = ["10.0.1.0/24", "10.0.2.0/24"]
private_subnet_cidrs   = ["10.0.10.0/24", "10.0.11.0/24"]
database_subnet_cidrs  = ["10.0.20.0/24", "10.0.21.0/24"]

# Database Configuration
db_name                   = "app"
db_username               = "postgres"
rds_instance_class        = "db.t3.micro"
rds_allocated_storage     = 20
rds_multi_az              = false # Single-AZ for dev
rds_backup_retention_days = 7

# ECS Configuration
ecs_desired_count = 1
task_cpu          = 256 # 0.25 vCPU
task_memory       = 512 # 512 MB

# Auto-scaling Configuration
enable_autoscaling       = false # Disabled for dev
autoscaling_min_capacity = 1
autoscaling_max_capacity = 2

# Application Configuration
domain               = "localhost"
frontend_host        = "http://localhost:5173"
backend_cors_origins = "http://localhost,http://localhost:5173"
first_superuser      = "admin@example.com"
emails_from_email    = "noreply@example.com"

# Secrets are managed via SSM Parameter Store (SecureString).
# See ssm.tf for naming convention.

# Email Configuration (optional for dev)
smtp_host = ""
smtp_user = ""
smtp_port = 587
smtp_tls  = true
smtp_ssl  = false

# Monitoring Configuration
sentry_dsn         = "" # Optional for dev
log_retention_days = 7
enable_alarms      = false

# Docker Image Configuration
backend_image_tag   = "latest"
ecr_repository_name = "backend"

# GitHub OIDC (set to "org/repo" to create IAM role for GitHub Actions; output role ARN as AWS_ROLE_ARN secret)
github_repository           = ""
github_oidc_branch          = "main"
github_oidc_create_provider = true # Create OIDC provider once per account (true only in one env, e.g. dev)

# Tags
common_tags = {
  Environment = "dev"
  Owner       = "DevOps Team"
  CostCenter  = "Engineering"
}
