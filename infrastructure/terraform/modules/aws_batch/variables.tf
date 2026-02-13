variable "context" {
  description = "Context object containing project, environment, region, and common tags"
  type = object({
    project     = string
    environment = string
    region      = string
    common_tags = map(string)
  })
}

variable "compute_environments" {
  description = "Map of compute environment definitions to create"
  type        = any
  default     = null
}

variable "create_job_queues" {
  description = "Determines whether to create job queues"
  type        = bool
  default     = true
}

variable "job_queues" {
  description = "Map of job queue and scheduling policy definitions to create"
  type        = any
  default     = null
}

variable "job_definitions" {
  description = "Map of job definitions to create"
  type        = any
  default     = null
}

# Instance IAM role
variable "create_instance_iam_role" {
  description = "Determines whether an IAM role is created or to use an existing IAM role for compute instances"
  type        = bool
  default     = true
}

variable "instance_iam_role_name" {
  description = "Compute instance IAM role name"
  type        = string
  default     = null
}

variable "instance_iam_role_use_name_prefix" {
  description = "Determines whether the IAM role name is used as a prefix"
  type        = bool
  default     = true
}

variable "instance_iam_role_path" {
  description = "Compute instance IAM role path"
  type        = string
  default     = null
}

variable "instance_iam_role_description" {
  description = "Compute instance IAM role description"
  type        = string
  default     = null
}

variable "instance_iam_role_permissions_boundary" {
  description = "ARN of the policy that is used to set the permissions boundary for the instance IAM role"
  type        = string
  default     = null
}

variable "instance_iam_role_additional_policies" {
  description = "Additional policies to be added to the instance IAM role"
  type        = map(string)
  default     = {}
}

variable "instance_iam_role_tags" {
  description = "Additional tags to add to the instance IAM role"
  type        = map(string)
  default     = {}
}

# Service IAM role
variable "create_service_iam_role" {
  description = "Determines whether an IAM role is created or to use an existing IAM role for the Batch service"
  type        = bool
  default     = true
}

variable "service_iam_role_name" {
  description = "Batch service IAM role name"
  type        = string
  default     = null
}

variable "service_iam_role_use_name_prefix" {
  description = "Determines whether the IAM role name is used as a prefix"
  type        = bool
  default     = true
}

variable "service_iam_role_path" {
  description = "Batch service IAM role path"
  type        = string
  default     = null
}

variable "service_iam_role_description" {
  description = "Batch service IAM role description"
  type        = string
  default     = null
}

variable "service_iam_role_permissions_boundary" {
  description = "ARN of the policy that is used to set the permissions boundary for the service IAM role"
  type        = string
  default     = null
}

variable "service_iam_role_additional_policies" {
  description = "Additional policies to be added to the service IAM role"
  type        = map(string)
  default     = {}
}

variable "service_iam_role_tags" {
  description = "Additional tags to add to the service IAM role"
  type        = map(string)
  default     = {}
}

# Spot Fleet IAM role
variable "create_spot_fleet_iam_role" {
  description = "Determines whether an IAM role is created or to use an existing IAM role for spot fleet"
  type        = bool
  default     = false
}

variable "spot_fleet_iam_role_name" {
  description = "Spot fleet IAM role name"
  type        = string
  default     = null
}

variable "spot_fleet_iam_role_use_name_prefix" {
  description = "Determines whether the IAM role name is used as a prefix"
  type        = bool
  default     = true
}

variable "spot_fleet_iam_role_path" {
  description = "Spot fleet IAM role path"
  type        = string
  default     = null
}

variable "spot_fleet_iam_role_description" {
  description = "Spot fleet IAM role description"
  type        = string
  default     = null
}

variable "spot_fleet_iam_role_permissions_boundary" {
  description = "ARN of the policy that is used to set the permissions boundary for the spot fleet IAM role"
  type        = string
  default     = null
}

variable "spot_fleet_iam_role_additional_policies" {
  description = "Additional policies to be added to the spot fleet IAM role"
  type        = map(string)
  default     = {}
}

variable "spot_fleet_iam_role_tags" {
  description = "Additional tags to add to the spot fleet IAM role"
  type        = map(string)
  default     = {}
}

variable "tags" {
  description = "Additional tags to merge with common tags"
  type        = map(string)
  default     = {}
}
