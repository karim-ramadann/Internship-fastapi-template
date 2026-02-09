variable "context" {
  description = "Context object containing project, environment, region, and common tags"
  type = object({
    project     = string
    environment = string
    region      = string
    common_tags = map(string)
  })
}

variable "log_retention_days" {
  description = "CloudWatch log retention period in days"
  type        = number
  default     = 7
}

variable "enable_alarms" {
  description = "Enable CloudWatch alarms"
  type        = bool
  default     = false
}

variable "ecs_cluster_name" {
  description = "Name of the ECS cluster (required if enable_alarms is true)"
  type        = string
  default     = ""
}

variable "ecs_service_name" {
  description = "Name of the ECS service (required if enable_alarms is true)"
  type        = string
  default     = ""
}

variable "alb_arn_suffix" {
  description = "ARN suffix of the ALB (required if enable_alarms is true)"
  type        = string
  default     = ""
}

variable "rds_instance_id" {
  description = "ID of the RDS instance (required if enable_alarms is true)"
  type        = string
  default     = ""
}

variable "ecs_cpu_threshold" {
  description = "ECS CPU utilization threshold percentage"
  type        = number
  default     = 80
}

variable "ecs_memory_threshold" {
  description = "ECS memory utilization threshold percentage"
  type        = number
  default     = 80
}

variable "rds_cpu_threshold" {
  description = "RDS CPU utilization threshold percentage"
  type        = number
  default     = 80
}

variable "rds_storage_threshold_bytes" {
  description = "RDS free storage space threshold in bytes (default 5GB)"
  type        = number
  default     = 5368709120 # 5 GB
}
