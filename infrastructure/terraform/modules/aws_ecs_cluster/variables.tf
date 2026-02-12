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
  description = "Name identifier for the ECS cluster (will be prefixed with project-environment)"
  type        = string
  default     = "cluster"
}

# Cluster configuration
variable "cluster_configuration" {
  description = "The execute command configuration for the cluster"
  type = object({
    execute_command_configuration = optional(object({
      kms_key_id = optional(string)
      log_configuration = optional(object({
        cloud_watch_encryption_enabled = optional(bool)
        cloud_watch_log_group_name     = optional(string)
        s3_bucket_encryption_enabled   = optional(bool)
        s3_bucket_name                 = optional(string)
        s3_kms_key_id                  = optional(string)
        s3_key_prefix                  = optional(string)
      }))
      logging = optional(string, "OVERRIDE")
    }))
    managed_storage_configuration = optional(object({
      fargate_ephemeral_storage_kms_key_id = optional(string)
      kms_key_id                           = optional(string)
    }))
  })
  default = null
}

variable "cluster_setting" {
  description = "List of configuration block(s) with cluster settings"
  type = list(object({
    name  = string
    value = string
  }))
  default = [
    {
      name  = "containerInsights"
      value = "enabled"
    }
  ]
}

variable "cluster_service_connect_defaults" {
  description = "Configures a default Service Connect namespace"
  type = object({
    namespace = string
  })
  default = null
}

# Capacity providers
variable "cluster_capacity_providers" {
  description = "List of capacity provider names to associate with the ECS cluster (e.g., FARGATE, FARGATE_SPOT)"
  type        = list(string)
  default     = ["FARGATE", "FARGATE_SPOT"]
}

variable "default_capacity_provider_strategy" {
  description = "Map of default capacity provider strategy definitions to use for the cluster"
  type = map(object({
    base   = optional(number)
    name   = optional(string)
    weight = optional(number)
  }))
  default = null
}

variable "capacity_providers" {
  description = "Map of capacity provider definitions to create for the cluster"
  type        = any
  default     = null
}

# CloudWatch logging
variable "create_cloudwatch_log_group" {
  description = "Determines whether a log group is created by this module for the cluster logs"
  type        = bool
  default     = true
}

variable "cloudwatch_log_group_name" {
  description = "Custom name of CloudWatch Log Group for ECS cluster"
  type        = string
  default     = null
}

variable "cloudwatch_log_group_retention_in_days" {
  description = "Number of days to retain log events"
  type        = number
  default     = 90
}

variable "cloudwatch_log_group_kms_key_id" {
  description = "KMS Key ARN to use for encrypting the CloudWatch log group"
  type        = string
  default     = null
}

variable "cloudwatch_log_group_class" {
  description = "Specified the log class of the log group. Possible values are: STANDARD or INFREQUENT_ACCESS"
  type        = string
  default     = null
}

variable "cloudwatch_log_group_tags" {
  description = "Additional tags to add to the CloudWatch log group"
  type        = map(string)
  default     = {}
}

# Infrastructure IAM role
variable "create_infrastructure_iam_role" {
  description = "Determines whether the ECS infrastructure IAM role should be created"
  type        = bool
  default     = true
}

variable "infrastructure_iam_role_name" {
  description = "Name to use on IAM role created for ECS infrastructure"
  type        = string
  default     = null
}

variable "infrastructure_iam_role_use_name_prefix" {
  description = "Determines whether the IAM role name is used as a prefix"
  type        = bool
  default     = true
}

variable "infrastructure_iam_role_path" {
  description = "IAM role path for infrastructure role"
  type        = string
  default     = null
}

variable "infrastructure_iam_role_description" {
  description = "Description of the infrastructure IAM role"
  type        = string
  default     = null
}

variable "infrastructure_iam_role_permissions_boundary" {
  description = "ARN of the policy that is used to set the permissions boundary for the infrastructure IAM role"
  type        = string
  default     = null
}

variable "infrastructure_iam_role_statements" {
  description = "Map of IAM policy statements for the infrastructure role"
  type        = any
  default     = null
}

variable "infrastructure_iam_role_tags" {
  description = "Additional tags to add to the infrastructure IAM role"
  type        = map(string)
  default     = {}
}

# Node IAM role (for EC2 instances)
variable "create_node_iam_instance_profile" {
  description = "Determines whether an IAM instance profile is created or to use an existing IAM instance profile"
  type        = bool
  default     = true
}

variable "node_iam_role_name" {
  description = "Name to use on IAM role/instance profile created for ECS nodes"
  type        = string
  default     = null
}

variable "node_iam_role_use_name_prefix" {
  description = "Determines whether the IAM role/instance profile name is used as a prefix"
  type        = bool
  default     = true
}

variable "node_iam_role_path" {
  description = "IAM role/instance profile path"
  type        = string
  default     = null
}

variable "node_iam_role_description" {
  description = "Description of the node IAM role"
  type        = string
  default     = "ECS Managed Instances node IAM role"
}

variable "node_iam_role_permissions_boundary" {
  description = "ARN of the policy that is used to set the permissions boundary for the node IAM role"
  type        = string
  default     = null
}

variable "node_iam_role_additional_policies" {
  description = "Additional policies to be added to the node IAM role"
  type        = map(string)
  default     = {}
}

variable "node_iam_role_statements" {
  description = "Map of IAM policy statements for the node role"
  type        = any
  default     = null
}

variable "node_iam_role_tags" {
  description = "Additional tags to add to the node IAM role"
  type        = map(string)
  default     = {}
}

# Task execution IAM role
variable "create_task_exec_iam_role" {
  description = "Determines whether the ECS task definition IAM role should be created"
  type        = bool
  default     = false
}

variable "create_task_exec_policy" {
  description = "Determines whether the ECS task definition IAM policy should be created"
  type        = bool
  default     = true
}

variable "cluster_tags" {
  description = "Additional tags to add to the cluster resource"
  type        = map(string)
  default     = {}
}

variable "tags" {
  description = "Additional tags to merge with common tags"
  type        = map(string)
  default     = {}
}
