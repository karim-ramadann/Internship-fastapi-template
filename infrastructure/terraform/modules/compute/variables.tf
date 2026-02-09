variable "context" {
  description = "Context object containing project, environment, region, and common tags"
  type = object({
    project     = string
    environment = string
    region      = string
    common_tags = map(string)
  })
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs for ECS tasks"
  type        = list(string)
}

variable "ecs_security_group_id" {
  description = "ID of the ECS security group"
  type        = string
}

variable "ecs_instance_profile_name" {
  description = "Name of the IAM instance profile for ECS EC2 instances"
  type        = string
}

variable "ecs_task_execution_role_arn" {
  description = "ARN of the ECS task execution role"
  type        = string
}

variable "ecs_task_role_arn" {
  description = "ARN of the ECS task role"
  type        = string
}

variable "backend_repository_url" {
  description = "URL of the backend ECR repository"
  type        = string
}

variable "frontend_repository_url" {
  description = "URL of the frontend ECR repository"
  type        = string
}

variable "backend_image_tag" {
  description = "Docker image tag for backend"
  type        = string
  default     = "latest"
}

variable "frontend_image_tag" {
  description = "Docker image tag for frontend"
  type        = string
  default     = "latest"
}

variable "rds_address" {
  description = "RDS instance address"
  type        = string
}

variable "backend_target_group_arn" {
  description = "ARN of the backend target group"
  type        = string
}

variable "frontend_target_group_arn" {
  description = "ARN of the frontend target group"
  type        = string
}

variable "adminer_target_group_arn" {
  description = "ARN of the adminer target group"
  type        = string
}

variable "backend_log_group_name" {
  description = "Name of the backend CloudWatch log group"
  type        = string
}

variable "frontend_log_group_name" {
  description = "Name of the frontend CloudWatch log group"
  type        = string
}

variable "adminer_log_group_name" {
  description = "Name of the adminer CloudWatch log group"
  type        = string
}

variable "prestart_log_group_name" {
  description = "Name of the prestart CloudWatch log group"
  type        = string
}

variable "common_environment_variables" {
  description = "Common environment variables for containers"
  type = list(object({
    name  = string
    value = string
  }))
  default = []
}

variable "common_secrets" {
  description = "Common secrets from SSM for containers"
  type = list(object({
    name      = string
    valueFrom = string
  }))
  default = []
}

variable "instance_type" {
  description = "EC2 instance type for ECS cluster"
  type        = string
  default     = "t3.medium"
}

variable "asg_min_size" {
  description = "Minimum size of the Auto Scaling Group"
  type        = number
  default     = 1
}

variable "asg_max_size" {
  description = "Maximum size of the Auto Scaling Group"
  type        = number
  default     = 3
}

variable "asg_desired_capacity" {
  description = "Desired capacity of the Auto Scaling Group"
  type        = number
  default     = 1
}

variable "task_cpu" {
  description = "CPU units for the task"
  type        = string
  default     = "1024"
}

variable "task_memory" {
  description = "Memory (MiB) for the task"
  type        = string
  default     = "2048"
}

variable "desired_count" {
  description = "Desired number of ECS tasks"
  type        = number
  default     = 1
}

variable "service_discovery_registry_arn" {
  description = "ARN of the service discovery registry (optional)"
  type        = string
  default     = null
}
