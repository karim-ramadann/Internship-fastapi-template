# ==============================================================================
# ECS Fargate Wrapper Module - Variables
# ==============================================================================

variable "context" {
  description = "Context object containing project, environment, region, and common tags"
  type = object({
    project     = string
    environment = string
    region      = string
    common_tags = map(string)
  })
}

# ------------------------------------------------------------------------------
# Cluster Configuration
# ------------------------------------------------------------------------------

variable "enable_container_insights" {
  description = "Enable CloudWatch Container Insights for the cluster"
  type        = bool
  default     = true
}

variable "create_cloudwatch_log_group" {
  description = "Whether the ECS module creates a CloudWatch log group for the cluster"
  type        = bool
  default     = true
}

variable "cloudwatch_log_group_retention_in_days" {
  description = "Number of days to retain cluster-level log events"
  type        = number
  default     = 30
}

# ------------------------------------------------------------------------------
# Service / Task Definition
# ------------------------------------------------------------------------------

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

variable "desired_count" {
  description = "Desired number of running tasks"
  type        = number
  default     = 1
}

variable "assign_public_ip" {
  description = "Assign a public IP to the Fargate task ENI"
  type        = bool
  default     = false
}

variable "subnet_ids" {
  description = "Subnet IDs where Fargate tasks will run"
  type        = list(string)
}

variable "vpc_id" {
  description = "VPC ID for the ECS service security group"
  type        = string
}

# ------------------------------------------------------------------------------
# Container Definitions
# ------------------------------------------------------------------------------

variable "container_definitions" {
  description = <<-EOT
    Map of container definitions passed directly to the community module.
    Each key is the container name. Values use the community module's native
    attribute names (image, essential, command, port_mappings, dependencies,
    environment, secrets, health_check, etc.).

    Computed values (ECR URLs, SSM ARNs) are safe here because the map keys
    are static strings — only values can be unknown at plan time.

    Per-container CloudWatch log groups are configured via container_definition_defaults.
    Override per container by setting cloudwatch_log_group_name in the value.

    Example:
    container_definitions = {
      backend = {
        image     = "$${module.ecr.backend_repository_url}:latest"
        essential = true
        port_mappings = [{
          containerPort = 8000
          protocol      = "tcp"
          name          = "backend"
        }]
        environment = [{ name = "ENV", value = "staging" }]
        secrets     = [{ name = "SECRET_KEY", valueFrom = "arn:aws:ssm:..." }]
        cloudwatch_log_group_name = "staging/ecs/myapp/backend"
      }
    }
  EOT
  type    = any
  default = {}
}

# ------------------------------------------------------------------------------
# Log Configuration
# ------------------------------------------------------------------------------

variable "log_retention_days" {
  description = "CloudWatch log retention in days for container log groups"
  type        = number
  default     = 14
}

# ------------------------------------------------------------------------------
# Load Balancer
# ------------------------------------------------------------------------------

variable "load_balancers" {
  description = <<-EOT
    Map of load balancer attachments for the service.
    Example:
    load_balancers = {
      backend = {
        container_name   = "backend"
        container_port   = 8000
        target_group_arn = aws_lb_target_group.backend.arn
      }
    }
  EOT
  type = map(object({
    container_name   = string
    container_port   = number
    target_group_arn = string
  }))
  default = {}
}

variable "health_check_grace_period_seconds" {
  description = "Seconds to wait before ECS starts checking ALB health for new tasks"
  type        = number
  default     = 180
}

# ------------------------------------------------------------------------------
# Networking / Security
# ------------------------------------------------------------------------------

variable "security_group_rules" {
  description = <<-EOT
    Map of ingress/egress rules for the ECS service security group.
    Example:
    security_group_rules = {
      backend_ingress = {
        type                     = "ingress"
        from_port                = 8000
        to_port                  = 8000
        protocol                 = "tcp"
        source_security_group_id = module.security.alb_security_group_id
      }
    }
  EOT
  type = map(object({
    type                     = string
    from_port                = number
    to_port                  = number
    protocol                 = string
    cidr_ipv4                = optional(string, null)
    source_security_group_id = optional(string, null)
    description              = optional(string, "")
  }))
  default = {}
}

# ------------------------------------------------------------------------------
# IAM
# ------------------------------------------------------------------------------

variable "task_exec_ssm_param_arns" {
  description = "List of SSM Parameter Store ARNs the task execution role can read (for secrets injection)"
  type        = list(string)
  default     = []
}

variable "task_exec_secret_arns" {
  description = "List of Secrets Manager ARNs the task execution role can read"
  type        = list(string)
  default     = []
}

variable "tasks_iam_role_statements" {
  description = "Additional IAM policy statements for the task role (application-level permissions)"
  type = list(object({
    sid       = optional(string)
    actions   = list(string)
    effect    = optional(string, "Allow")
    resources = list(string)
    condition = optional(list(object({
      test     = string
      values   = list(string)
      variable = string
    })), [])
  }))
  default = []
}

# ------------------------------------------------------------------------------
# Service Discovery
# ------------------------------------------------------------------------------

variable "service_registries" {
  description = "Service discovery registry configuration"
  type = object({
    registry_arn   = string
    container_name = optional(string, null)
    container_port = optional(number, null)
  })
  default = null
}

# ------------------------------------------------------------------------------
# Autoscaling
# ------------------------------------------------------------------------------

variable "enable_autoscaling" {
  description = "Enable Application Auto Scaling for the service"
  type        = bool
  default     = false
}

variable "autoscaling_min_capacity" {
  description = "Minimum number of tasks"
  type        = number
  default     = 1
}

variable "autoscaling_max_capacity" {
  description = "Maximum number of tasks"
  type        = number
  default     = 10
}

variable "autoscaling_policies" {
  description = <<-EOT
    Map of autoscaling policy configurations. Supports target tracking.
    Example:
    autoscaling_policies = {
      cpu = {
        policy_type = "TargetTrackingScaling"
        target_tracking_scaling_policy_configuration = {
          predefined_metric_specification = {
            predefined_metric_type = "ECSServiceAverageCPUUtilization"
          }
          target_value       = 70
          scale_in_cooldown  = 300
          scale_out_cooldown = 60
        }
      }
    }
  EOT
  type        = any
  default     = {}
}

# ------------------------------------------------------------------------------
# Deployment
# ------------------------------------------------------------------------------

variable "deployment_maximum_percent" {
  description = "Upper limit (% of desired_count) of tasks during deployment"
  type        = number
  default     = 200
}

variable "deployment_minimum_healthy_percent" {
  description = "Lower limit (% of desired_count) of tasks that must remain healthy during deployment"
  type        = number
  default     = 100
}

variable "enable_deployment_circuit_breaker" {
  description = "Enable ECS deployment circuit breaker with rollback"
  type        = bool
  default     = true
}

variable "force_new_deployment" {
  description = "Force a new deployment of the service (useful for image tag updates)"
  type        = bool
  default     = false
}

variable "wait_for_steady_state" {
  description = "Wait for the service to reach a steady state after deployment"
  type        = bool
  default     = false
}

variable "ignore_task_definition_changes" {
  description = "Ignore changes to the task definition (useful when CI/CD updates it externally)"
  type        = bool
  default     = false
}
