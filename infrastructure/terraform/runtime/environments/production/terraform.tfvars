# ============================================================================
# Production Environment Configuration
# ============================================================================
# This configuration provides high availability, automated backups, and
# enhanced monitoring for production workloads.
# ============================================================================

# Environment Configuration
environment = "production"
project     = "fastapi"
aws_region  = "eu-west-1"

# Networking Configuration
vpc_cidr               = "10.0.0.0/16"
single_nat_gateway     = false # High availability
one_nat_gateway_per_az = true  # One NAT Gateway per AZ
public_subnet_cidrs    = ["10.0.1.0/24", "10.0.2.0/24"]
private_subnet_cidrs   = ["10.0.10.0/24", "10.0.11.0/24"]
database_subnet_cidrs  = ["10.0.20.0/24", "10.0.21.0/24"]

# Database Configuration
db_name                   = "app"
db_username               = "postgres"
rds_instance_class        = "db.t4g.medium"
rds_allocated_storage     = 100
rds_multi_az              = true # High availability
rds_backup_retention_days = 30

# ECS Configuration
ecs_desired_count = 2    # Run at least 2 tasks for HA
task_cpu          = 1024 # 1 vCPU
task_memory       = 2048 # 2 GB

# Auto-scaling Configuration
enable_autoscaling       = true
autoscaling_min_capacity = 2
autoscaling_max_capacity = 10

# Application Configuration
domain               = "example.com"
frontend_host        = "https://app.example.com"
backend_cors_origins = "https://app.example.com"
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
log_retention_days = 30
enable_alarms      = true

# Docker Image Configuration
backend_image_tag   = "production-latest"
ecr_repository_name = "backend"

# Tags
common_tags = {
  Environment = "production"
  Owner       = "DevOps Team"
  CostCenter  = "Engineering"
  Backup      = "Required"
}
