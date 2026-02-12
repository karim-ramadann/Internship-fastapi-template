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
  description = "Name identifier for the Step Function (will be prefixed with project-environment)"
  type        = string
}

variable "definition" {
  description = "The Amazon States Language definition of the Step Function"
  type        = string
}

variable "type" {
  description = "Determines whether a Standard or Express state machine is created. Valid Values: STANDARD | EXPRESS"
  type        = string
  default     = "STANDARD"
}

variable "publish" {
  description = "Determines whether to set a version of the state machine when it is created"
  type        = bool
  default     = false
}

# IAM role
variable "create_role" {
  description = "Whether to create IAM role for the Step Function"
  type        = bool
  default     = true
}

variable "use_existing_role" {
  description = "Whether to use an existing IAM role for this Step Function"
  type        = bool
  default     = false
}

variable "role_arn" {
  description = "The Amazon Resource Name (ARN) of the IAM role to use for this Step Function"
  type        = string
  default     = ""
}

variable "role_name" {
  description = "Name of IAM role to use for Step Function"
  type        = string
  default     = null
}

variable "role_description" {
  description = "Description of IAM role to use for Step Function"
  type        = string
  default     = null
}

variable "role_path" {
  description = "Path of IAM role to use for Step Function"
  type        = string
  default     = null
}

variable "role_permissions_boundary" {
  description = "The ARN of the policy that is used to set the permissions boundary for the IAM role"
  type        = string
  default     = null
}

variable "role_force_detach_policies" {
  description = "Specifies to force detaching any policies the IAM role has before destroying it"
  type        = bool
  default     = true
}

variable "role_tags" {
  description = "Additional tags to assign to IAM role"
  type        = map(string)
  default     = {}
}

# Service integrations
variable "attach_policies_for_integrations" {
  description = "Whether to attach AWS Service policies to IAM role"
  type        = bool
  default     = true
}

variable "service_integrations" {
  description = "Map of AWS service integrations to allow in IAM role policy"
  type        = any
  default     = {}
}

# Additional IAM policies
variable "attach_policy" {
  description = "Controls whether policy should be added to IAM role"
  type        = bool
  default     = false
}

variable "policy" {
  description = "An additional policy document ARN to attach to IAM role"
  type        = string
  default     = null
}

variable "attach_policies" {
  description = "Controls whether list of policies should be added to IAM role"
  type        = bool
  default     = false
}

variable "policies" {
  description = "List of policy statements ARN to attach to IAM role"
  type        = list(string)
  default     = []
}

variable "number_of_policies" {
  description = "Number of policies to attach to IAM role"
  type        = number
  default     = 0
}

variable "attach_policy_json" {
  description = "Controls whether policy_json should be added to IAM role"
  type        = bool
  default     = false
}

variable "policy_json" {
  description = "An additional policy document as JSON to attach to IAM role"
  type        = string
  default     = null
}

variable "attach_policy_jsons" {
  description = "Controls whether policy_jsons should be added to IAM role"
  type        = bool
  default     = false
}

variable "policy_jsons" {
  description = "List of additional policy documents as JSON to attach to IAM role"
  type        = list(string)
  default     = []
}

variable "number_of_policy_jsons" {
  description = "Number of policies JSON to attach to IAM role"
  type        = number
  default     = 0
}

variable "attach_policy_statements" {
  description = "Controls whether policy_statements should be added to IAM role"
  type        = bool
  default     = false
}

variable "policy_statements" {
  description = "Map of dynamic policy statements to attach to IAM role"
  type        = any
  default     = {}
}

variable "policy_path" {
  description = "Path of IAM policies to use for Step Function"
  type        = string
  default     = null
}

# CloudWatch Logs
variable "attach_cloudwatch_logs_policy" {
  description = "Controls whether CloudWatch Logs policy should be added to IAM role"
  type        = bool
  default     = true
}

variable "logging_configuration" {
  description = "Defines what execution history events are logged and where they are logged"
  type        = map(string)
  default     = {}
}

variable "use_existing_cloudwatch_log_group" {
  description = "Whether to use an existing CloudWatch log group or create new"
  type        = bool
  default     = false
}

variable "cloudwatch_log_group_name" {
  description = "Name of CloudWatch Logs group name to use"
  type        = string
  default     = null
}

variable "cloudwatch_log_group_retention_in_days" {
  description = "Specifies the number of days you want to retain log events in the specified log group"
  type        = number
  default     = null
}

variable "cloudwatch_log_group_kms_key_id" {
  description = "The ARN of the KMS Key to use when encrypting log data"
  type        = string
  default     = null
}

variable "cloudwatch_log_group_tags" {
  description = "Additional tags to assign to CloudWatch log group"
  type        = map(string)
  default     = {}
}

# Encryption
variable "encryption_configuration" {
  description = "Defines what encryption configuration is used to encrypt data in the State Machine"
  type        = any
  default     = {}
}

# Assume role
variable "aws_region_assume_role" {
  description = "Name of AWS regions where IAM role can be assumed by the Step Function"
  type        = string
  default     = ""
}

variable "trusted_entities" {
  description = "Step Function additional trusted entities for assuming roles (trust relationship)"
  type        = list(string)
  default     = []
}

# Timeouts
variable "sfn_state_machine_timeouts" {
  description = "Create, update, and delete timeout configurations for the step function"
  type        = map(string)
  default     = {}
}

variable "tags" {
  description = "Additional tags to merge with common tags"
  type        = map(string)
  default     = {}
}
