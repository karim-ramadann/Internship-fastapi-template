# ============================================================================
# Staging Environment Configuration
# ============================================================================
# This configuration provides a production-like environment for pre-production
# testing and validation. Resources are moderately sized with optional HA.
# ============================================================================

# Environment Configuration
environment = "staging"
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
rds_instance_class        = "db.t3.small"
rds_allocated_storage     = 50
rds_multi_az              = false # Can be enabled if needed
rds_backup_retention_days = 14

# ECS Configuration
ecs_desired_count = 1
task_cpu          = 512  # 0.5 vCPU
task_memory       = 1024 # 1 GB

# Auto-scaling Configuration
enable_autoscaling       = true
autoscaling_min_capacity = 1
autoscaling_max_capacity = 3

# Application Configuration
domain               = "staging.example.com"
frontend_host        = "https://staging.example.com"
backend_cors_origins = "https://staging.example.com"
first_superuser      = "admin@example.com"
emails_from_email    = "noreply@example.com"

# Secrets are managed via SSM Parameter Store (SecureString).
# See ssm.tf for naming convention.

# Email Configuration
smtp_host = "smtp.example.com"
smtp_user = "noreply@example.com"
smtp_port = 587
smtp_tls  = true
smtp_ssl  = false

# Monitoring Configuration
sentry_dsn         = "" # Add Sentry DSN for error tracking
log_retention_days = 14
enable_alarms      = false

# Docker Image Configuration
backend_image_tag   = "staging-latest"
ecr_repository_name = "backend"

# Tags
common_tags = {
  Environment = "staging"
  Owner       = "DevOps Team"
  CostCenter  = "Engineering"
}
