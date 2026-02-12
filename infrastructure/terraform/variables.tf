# AWS Configuration
variable "aws_region" {
  description = "AWS region for all resources"
  type        = string
}

# Environment Configuration
variable "environment" {
  description = "Environment name (staging, production)"
  type        = string

  validation {
    condition     = contains(["staging", "production"], var.environment)
    error_message = "Environment must be either 'staging' or 'production'."
  }
}

variable "project" {
  description = "Project name"
  type        = string
  default     = "full-stack-fastapi-project"
}

# Domain Configuration
variable "domain" {
  description = "Base domain for the application"
  type        = string
}

variable "frontend_host" {
  description = "Frontend URL for email links"
  type        = string
}

# Backend Configuration
variable "secret_key" {
  description = "Secret key for JWT tokens"
  type        = string
  sensitive   = true
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

variable "backend_cors_origins" {
  description = "Allowed CORS origins (comma-separated)"
  type        = string
}

# SMTP Configuration
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

# Sentry Configuration
variable "sentry_dsn" {
  description = "Sentry DSN"
  type        = string
  default     = ""
}

# Database Configuration
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

# Infrastructure Sizing
variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "ec2_instance_type" {
  description = "EC2 instance type for ECS cluster"
  type        = string
  default     = "t3.medium"
}

variable "ecs_desired_count" {
  description = "Desired number of ECS tasks"
  type        = number
  default     = 1
}

variable "task_cpu" {
  description = "CPU units for the ECS task"
  type        = string
  default     = "1024"
}

variable "task_memory" {
  description = "Memory (MiB) for the ECS task"
  type        = string
  default     = "2048"
}

variable "enable_service_discovery" {
  description = "Enable AWS Cloud Map service discovery for ECS services"
  type        = bool
  default     = true
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

# Docker Image Tags (passed from CI/CD)
variable "backend_image_tag" {
  description = "Docker image tag for backend (e.g., staging-abc1234)"
  type        = string
  default     = "latest"
}

variable "frontend_image_tag" {
  description = "Docker image tag for frontend (e.g., staging-abc1234)"
  type        = string
  default     = "latest"
}

variable "lambda_image_uri" {
  description = "Full ECR image URI for the Lambda function (e.g., 123456789012.dkr.ecr.us-east-1.amazonaws.com/my-repo:latest)"
  type        = string
}

# Route53 Configuration
variable "create_hosted_zone" {
  description = "Whether to create a new Route53 hosted zone or use an existing one"
  type        = bool
  default     = false
}

# Common Tags
variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}
