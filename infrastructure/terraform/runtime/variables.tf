# ============================================================================
# Core Configuration Variables
# ============================================================================

variable "aws_region" {
  description = "AWS region for all resources"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, production)"
  type        = string

  validation {
    condition     = contains(["dev", "staging", "production"], var.environment)
    error_message = "Environment must be either 'dev', 'staging', or 'production'."
  }
}

variable "project" {
  description = "Project name"
  type        = string
  default     = "full-stack-fastapi-project"
}

# ============================================================================
# Networking Variables
# ============================================================================

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "single_nat_gateway" {
  description = "Use a single NAT Gateway for all private subnets (cost-effective for dev/staging)"
  type        = bool
  default     = true
}

variable "one_nat_gateway_per_az" {
  description = "Create one NAT Gateway per availability zone (recommended for production)"
  type        = bool
  default     = false
}

# ============================================================================
# Database Variables
# ============================================================================

variable "db_name" {
  description = "Database name"
  type        = string
  default     = "app"
}

variable "db_username" {
  description = "Database master username"
  type        = string
  default     = "postgres"
}

variable "rds_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "rds_allocated_storage" {
  description = "RDS allocated storage in GB"
  type        = number
  default     = 20
}

variable "rds_multi_az" {
  description = "Enable Multi-AZ deployment for RDS"
  type        = bool
  default     = false
}

variable "rds_backup_retention_days" {
  description = "RDS backup retention period in days"
  type        = number
  default     = 7
}

# ============================================================================
# ECS Variables
# ============================================================================

variable "ecs_desired_count" {
  description = "Desired number of ECS tasks"
  type        = number
  default     = 1
}

variable "task_cpu" {
  description = "CPU units for the Fargate task (256, 512, 1024, 2048, 4096)"
  type        = number
  default     = 1024
}

variable "task_memory" {
  description = "Memory (MiB) for the Fargate task"
  type        = number
  default     = 2048
}

variable "enable_autoscaling" {
  description = "Enable auto-scaling for ECS service"
  type        = bool
  default     = false
}

variable "autoscaling_min_capacity" {
  description = "Minimum number of tasks for auto-scaling"
  type        = number
  default     = 1
}

variable "autoscaling_max_capacity" {
  description = "Maximum number of tasks for auto-scaling"
  type        = number
  default     = 10
}

# ============================================================================
# Application Configuration Variables
# ============================================================================

variable "domain" {
  description = "Base domain for the application"
  type        = string
}

variable "frontend_host" {
  description = "Frontend URL for email links"
  type        = string
}

variable "backend_cors_origins" {
  description = "Allowed CORS origins (comma-separated)"
  type        = string
}

variable "first_superuser" {
  description = "Email for first superuser"
  type        = string
}

variable "first_superuser_password" {
  description = "Password for first superuser"
  type        = string
  sensitive   = true
}

variable "secret_key" {
  description = "Backend secret key for JWT tokens"
  type        = string
  sensitive   = true
}

# ============================================================================
# Email Configuration Variables
# ============================================================================

variable "smtp_host" {
  description = "SMTP server host"
  type        = string
  default     = ""
}

variable "smtp_user" {
  description = "SMTP server user"
  type        = string
  default     = ""
}

variable "smtp_password" {
  description = "SMTP server password"
  type        = string
  default     = ""
  sensitive   = true
}

variable "emails_from_email" {
  description = "Email address to send from"
  type        = string
}

variable "smtp_tls" {
  description = "Enable TLS for SMTP"
  type        = bool
  default     = true
}

variable "smtp_ssl" {
  description = "Enable SSL for SMTP"
  type        = bool
  default     = false
}

variable "smtp_port" {
  description = "SMTP server port"
  type        = number
  default     = 587
}

# ============================================================================
# Monitoring Variables
# ============================================================================

variable "sentry_dsn" {
  description = "Sentry DSN for error tracking"
  type        = string
  default     = ""
}

# ============================================================================
# Docker Image Variables
# ============================================================================

variable "backend_image_tag" {
  description = "Docker image tag for backend (e.g., latest, v1.0.0)"
  type        = string
  default     = "latest"
}

variable "ecr_repository_name" {
  description = "Name for the ECR repository"
  type        = string
  default     = "backend"
}

# ============================================================================
# Common Tags
# ============================================================================

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}
