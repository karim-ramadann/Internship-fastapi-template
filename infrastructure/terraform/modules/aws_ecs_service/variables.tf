variable "context" {
  description = "Context object containing project, environment, region, and common tags"
  type = object({
    project     = string
    environment = string
    region      = string
    common_tags = map(string)
  })
}

variable "name" {
  description = "Name identifier for the ECS service (will be prefixed with project-environment)"
  type        = string
}

variable "cluster_arn" {
  description = "ARN of the ECS cluster where the service will be deployed"
  type        = string
}

# Launch type and capacity
variable "launch_type" {
  description = "Launch type on which to run service. Valid values are EC2, FARGATE, or EXTERNAL"
  type        = string
  default     = "FARGATE"
}

variable "capacity_provider_strategy" {
  description = "Capacity provider strategy to use for the service"
  type = map(object({
    base              = optional(number)
    capacity_provider = string
    weight            = optional(number)
  }))
  default = null
}

variable "platform_version" {
  description = "Platform version on which to run your service (only applicable for FARGATE launch type)"
  type        = string
  default     = "LATEST"
}

# Task definition
variable "create_task_definition" {
  description = "Determines whether to create a task definition or use existing"
  type        = bool
  default     = true
}

variable "task_definition_arn" {
  description = "ARN of existing task definition to use (if create_task_definition is false)"
  type        = string
  default     = null
}

variable "cpu" {
  description = "Number of CPU units used by the task"
  type        = number
  default     = 256
}

variable "memory" {
  description = "Amount (in MiB) of memory used by the task"
  type        = number
  default     = 512
}

variable "requires_compatibilities" {
  description = "Set of launch types required by the task. Valid values are EC2 and FARGATE"
  type        = list(string)
  default     = ["FARGATE"]
}

variable "container_definitions" {
  description = "Map of container definitions to create"
  type        = any
}

variable "volume" {
  description = "Configuration block for volumes that containers in your task may use"
  type        = any
  default     = {}
}

variable "ephemeral_storage" {
  description = "The amount of ephemeral storage to allocate for the task (in GiB)"
  type = object({
    size_in_gib = number
  })
  default = null
}

# Networking
variable "assign_public_ip" {
  description = "Assign a public IP address to the ENI"
  type        = bool
  default     = false
}

variable "security_group_ids" {
  description = "List of security group IDs to associate with the task or service"
  type        = list(string)
  default     = []
}

variable "subnet_ids" {
  description = "List of subnet IDs to associate with the task or service"
  type        = list(string)
}

# Security group
variable "create_security_group" {
  description = "Determines whether to create a security group for the service"
  type        = bool
  default     = true
}

variable "security_group_name" {
  description = "Name to use on security group created"
  type        = string
  default     = null
}

variable "security_group_description" {
  description = "Description of the security group created"
  type        = string
  default     = null
}

variable "security_group_ingress_rules" {
  description = "Security group ingress rules to add to the security group created"
  type        = any
  default     = {}
}

variable "security_group_egress_rules" {
  description = "Security group egress rules to add to the security group created"
  type        = any
  default     = {}
}

variable "security_group_use_name_prefix" {
  description = "Determines whether the security group name is used as a prefix"
  type        = bool
  default     = true
}

variable "security_group_tags" {
  description = "Additional tags to add to the security group"
  type        = map(string)
  default     = {}
}

# Service configuration
variable "desired_count" {
  description = "Number of instances of the task definition to place and keep running"
  type        = number
  default     = 1
}

variable "deployment_minimum_healthy_percent" {
  description = "Lower limit on the number of running tasks that must remain healthy during deployment"
  type        = number
  default     = 100
}

variable "deployment_maximum_percent" {
  description = "Upper limit on the number of running tasks that can be running during deployment"
  type        = number
  default     = 200
}

variable "enable_execute_command" {
  description = "Specifies whether to enable Amazon ECS Exec for the tasks within the service"
  type        = bool
  default     = false
}

variable "enable_ecs_managed_tags" {
  description = "Specifies whether to enable Amazon ECS managed tags for the tasks within the service"
  type        = bool
  default     = true
}

variable "propagate_tags" {
  description = "Specifies whether to propagate the tags from the task definition or the service to the tasks"
  type        = string
  default     = "SERVICE"
}

variable "wait_for_steady_state" {
  description = "Wait for the service to reach a steady state before Terraform considers the operation complete"
  type        = bool
  default     = false
}

variable "force_new_deployment" {
  description = "Enable to force a new task deployment of the service"
  type        = bool
  default     = false
}

variable "health_check_grace_period_seconds" {
  description = "Seconds to ignore failing load balancer health checks on newly instantiated tasks"
  type        = number
  default     = null
}

# Deployment
variable "deployment_controller" {
  description = "Configuration block for deployment controller"
  type = object({
    type = optional(string)
  })
  default = null
}

variable "deployment_circuit_breaker" {
  description = "Configuration block for deployment circuit breaker"
  type = object({
    enable   = bool
    rollback = bool
  })
  default = null
}

# Load balancer
variable "load_balancer" {
  description = "Configuration block for load balancers"
  type = map(object({
    container_name   = string
    container_port   = number
    elb_name         = optional(string)
    target_group_arn = optional(string)
  }))
  default = {}
}

# Service Connect
variable "service_connect_configuration" {
  description = "Configuration block for Service Connect"
  type = object({
    enabled = optional(bool)
    log_configuration = optional(object({
      log_driver = string
      options    = optional(map(string))
      secret_option = optional(list(object({
        name       = string
        value_from = string
      })))
    }))
    namespace = optional(string)
    service = optional(list(object({
      client_alias = optional(object({
        dns_name = optional(string)
        port     = number
      }))
      discovery_name        = optional(string)
      ingress_port_override = optional(number)
      port_name             = string
    })))
  })
  default = null
}

# Service Discovery
variable "service_registries" {
  description = "Service discovery registries for the service"
  type = object({
    container_name = optional(string)
    container_port = optional(number)
    port           = optional(number)
    registry_arn   = string
  })
  default = null
}

# Auto-scaling
variable "enable_autoscaling" {
  description = "Determines whether to enable autoscaling for the service"
  type        = bool
  default     = false
}

variable "autoscaling_min_capacity" {
  description = "Minimum number of tasks to run in your service"
  type        = number
  default     = 1
}

variable "autoscaling_max_capacity" {
  description = "Maximum number of tasks to run in your service"
  type        = number
  default     = 10
}

variable "autoscaling_policies" {
  description = "Map of autoscaling policies to create for the service"
  type        = any
  default     = {}
}

variable "autoscaling_scheduled_actions" {
  description = "Map of autoscaling scheduled actions to create for the service"
  type        = any
  default     = {}
}

# Service IAM role
variable "create_iam_role" {
  description = "Determines whether the ECS service IAM role should be created"
  type        = bool
  default     = false
}

variable "iam_role_arn" {
  description = "ARN of existing IAM role to use for the service"
  type        = string
  default     = null
}

variable "iam_role_name" {
  description = "Name to use on IAM role created for the service"
  type        = string
  default     = null
}

variable "iam_role_use_name_prefix" {
  description = "Determines whether the IAM role name is used as a prefix"
  type        = bool
  default     = true
}

variable "iam_role_path" {
  description = "IAM role path"
  type        = string
  default     = null
}

variable "iam_role_description" {
  description = "Description of the IAM role"
  type        = string
  default     = null
}

variable "iam_role_permissions_boundary" {
  description = "ARN of the policy that is used to set the permissions boundary for the IAM role"
  type        = string
  default     = null
}

variable "iam_role_statements" {
  description = "Map of IAM policy statements for the service IAM role"
  type        = any
  default     = null
}

variable "iam_role_tags" {
  description = "Additional tags to add to the service IAM role"
  type        = map(string)
  default     = {}
}

# Task execution IAM role
variable "create_task_exec_iam_role" {
  description = "Determines whether the ECS task execution IAM role should be created"
  type        = bool
  default     = true
}

variable "task_exec_iam_role_arn" {
  description = "ARN of existing IAM role to use for task execution"
  type        = string
  default     = null
}

variable "task_exec_iam_role_name" {
  description = "Name to use on IAM role created for task execution"
  type        = string
  default     = null
}

variable "task_exec_iam_role_use_name_prefix" {
  description = "Determines whether the IAM role name is used as a prefix"
  type        = bool
  default     = true
}

variable "task_exec_iam_role_path" {
  description = "IAM role path"
  type        = string
  default     = null
}

variable "task_exec_iam_role_description" {
  description = "Description of the task execution IAM role"
  type        = string
  default     = null
}

variable "task_exec_iam_role_permissions_boundary" {
  description = "ARN of the policy that is used to set the permissions boundary for the task execution IAM role"
  type        = string
  default     = null
}

variable "task_exec_iam_role_tags" {
  description = "Additional tags to add to the task execution IAM role"
  type        = map(string)
  default     = {}
}

variable "task_exec_ssm_param_arns" {
  description = "List of SSM parameter ARNs the task execution role will be permitted to get/read"
  type        = list(string)
  default     = []
}

variable "task_exec_secret_arns" {
  description = "List of Secrets Manager secret ARNs the task execution role will be permitted to get/read"
  type        = list(string)
  default     = []
}

variable "task_exec_iam_role_policies" {
  description = "Map of IAM policies to attach to the task execution IAM role"
  type        = map(string)
  default     = {}
}

# Tasks IAM role
variable "create_tasks_iam_role" {
  description = "Determines whether the ECS tasks IAM role should be created"
  type        = bool
  default     = true
}

variable "tasks_iam_role_arn" {
  description = "ARN of existing IAM role to use for tasks"
  type        = string
  default     = null
}

variable "tasks_iam_role_name" {
  description = "Name to use on IAM role created for tasks"
  type        = string
  default     = null
}

variable "tasks_iam_role_use_name_prefix" {
  description = "Determines whether the IAM role name is used as a prefix"
  type        = bool
  default     = true
}

variable "tasks_iam_role_path" {
  description = "IAM role path"
  type        = string
  default     = null
}

variable "tasks_iam_role_description" {
  description = "Description of the tasks IAM role"
  type        = string
  default     = null
}

variable "tasks_iam_role_permissions_boundary" {
  description = "ARN of the policy that is used to set the permissions boundary for the tasks IAM role"
  type        = string
  default     = null
}

variable "tasks_iam_role_statements" {
  description = "Map of IAM policy statements for the tasks IAM role"
  type        = any
  default     = null
}

variable "tasks_iam_role_tags" {
  description = "Additional tags to add to the tasks IAM role"
  type        = map(string)
  default     = {}
}

variable "tasks_iam_role_policies" {
  description = "Map of IAM policies to attach to the tasks IAM role"
  type        = map(string)
  default     = {}
}

variable "tags" {
  description = "Additional tags to merge with common tags"
  type        = map(string)
  default     = {}
}
