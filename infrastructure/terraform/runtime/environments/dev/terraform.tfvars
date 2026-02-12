# ============================================================================
# Development Environment Configuration
# ============================================================================
# This configuration is optimized for cost-effective development and testing.
# Resources use minimal sizing and single-AZ deployment where possible.
# ============================================================================

# Environment Configuration
environment = "dev"
project     = "full-stack-fastapi-project"
aws_region  = "eu-west-1"

# Networking Configuration
vpc_cidr               = "10.0.0.0/16"
single_nat_gateway     = true  # Cost-effective: single NAT Gateway
one_nat_gateway_per_az = false

# Database Configuration
db_name                   = "app"
db_username               = "postgres"
rds_instance_class        = "db.t3.micro"
rds_allocated_storage     = 20
rds_multi_az              = false # Single-AZ for dev
rds_backup_retention_days = 7

# ECS Configuration
ecs_desired_count = 1
task_cpu          = 256  # 0.25 vCPU
task_memory       = 512  # 512 MB

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

# Secrets (should be set via environment variables or CI/CD)
# first_superuser_password = "changethis"  # Set via TF_VAR_first_superuser_password
# secret_key              = "changethis"   # Set via TF_VAR_secret_key

# Email Configuration (optional for dev)
smtp_host     = ""
smtp_user     = ""
smtp_port     = 587
smtp_tls      = true
smtp_ssl      = false
# smtp_password = ""  # Set via TF_VAR_smtp_password

# Monitoring Configuration
sentry_dsn = "" # Optional for dev

# Docker Image Configuration
backend_image_tag    = "latest"
ecr_repository_name  = "backend"

# Tags
common_tags = {
  Environment = "dev"
  Owner       = "DevOps Team"
  CostCenter  = "Engineering"
}
