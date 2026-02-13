variable "context" {
  description = "Context object containing project, environment, region, and common tags"
  type = object({
    project     = string
    environment = string
    region      = string
    common_tags = map(string)
  })
}

variable "create" {
  description = "Controls whether resources should be created"
  type        = bool
  default     = true
}

variable "bus_name" {
  description = "Name identifier for the EventBridge Bus (will be prefixed with project-environment). Use null for default bus"
  type        = string
  default     = null
}

variable "create_bus" {
  description = "Controls whether EventBridge Bus resource should be created"
  type        = bool
  default     = true
}

variable "bus_description" {
  description = "Event bus description"
  type        = string
  default     = null
}

variable "event_source_name" {
  description = "The partner event source that the new event bus will be matched with"
  type        = string
  default     = null
}

variable "kms_key_identifier" {
  description = "The identifier of the AWS KMS customer managed key for EventBridge to use"
  type        = string
  default     = null
}

# Logging
variable "log_config" {
  description = "The configuration block for the EventBridge bus log config settings"
  type = object({
    include_detail = string
    level          = string
  })
  default = null
}

variable "log_delivery" {
  description = "Map of the configuration block for the EventBridge bus log delivery settings"
  type        = any
  default     = {}
}

# Rules
variable "create_rules" {
  description = "Controls whether EventBridge Rule resources should be created"
  type        = bool
  default     = true
}

variable "rules" {
  description = "Map of EventBridge Rule definitions"
  type        = any
  default     = {}
}

# Targets
variable "create_targets" {
  description = "Controls whether EventBridge Target resources should be created"
  type        = bool
  default     = true
}

variable "targets" {
  description = "Map of EventBridge Target definitions"
  type        = any
  default     = {}
}

# Archives
variable "create_archives" {
  description = "Controls whether EventBridge Archive resources should be created"
  type        = bool
  default     = false
}

variable "archives" {
  description = "Map of EventBridge Archive definitions"
  type        = any
  default     = {}
}

# Permissions
variable "create_permissions" {
  description = "Controls whether EventBridge Permission resources should be created"
  type        = bool
  default     = true
}

variable "permissions" {
  description = "Map of EventBridge Permission definitions"
  type        = any
  default     = {}
}

# Connections and API Destinations
variable "create_connections" {
  description = "Controls whether EventBridge Connection resources should be created"
  type        = bool
  default     = false
}

variable "connections" {
  description = "Map of EventBridge Connection definitions"
  type        = any
  default     = {}
}

variable "create_api_destinations" {
  description = "Controls whether EventBridge Destination resources should be created"
  type        = bool
  default     = false
}

variable "api_destinations" {
  description = "Map of EventBridge Destination definitions"
  type        = any
  default     = {}
}

# Schedules
variable "create_schedule_groups" {
  description = "Controls whether EventBridge Schedule Group resources should be created"
  type        = bool
  default     = true
}

variable "schedule_groups" {
  description = "Map of EventBridge Schedule Group definitions"
  type        = any
  default     = {}
}

variable "create_schedules" {
  description = "Controls whether EventBridge Schedule resources should be created"
  type        = bool
  default     = true
}

variable "schedules" {
  description = "Map of EventBridge Schedule definitions"
  type        = any
  default     = {}
}

# Pipes
variable "create_pipes" {
  description = "Controls whether EventBridge Pipes resources should be created"
  type        = bool
  default     = true
}

variable "pipes" {
  description = "Map of EventBridge Pipe definitions"
  type        = any
  default     = {}
}

# Schema discovery
variable "create_schemas_discoverer" {
  description = "Controls whether default schemas discoverer should be created"
  type        = bool
  default     = false
}

# IAM role
variable "create_role" {
  description = "Controls whether IAM roles should be created"
  type        = bool
  default     = true
}

# Service integration policies
variable "attach_cloudwatch_policy" {
  description = "Controls whether the CloudWatch policy should be added to IAM role"
  type        = bool
  default     = false
}

variable "cloudwatch_target_arns" {
  description = "The ARNs of the CloudWatch Log Streams to use as EventBridge targets"
  type        = list(string)
  default     = []
}

variable "attach_ecs_policy" {
  description = "Controls whether the ECS policy should be added to IAM role"
  type        = bool
  default     = false
}

variable "ecs_target_arns" {
  description = "The ARNs of the AWS ECS Tasks to use as EventBridge targets"
  type        = list(string)
  default     = []
}

variable "ecs_pass_role_resources" {
  description = "List of approved roles to be passed for ECS tasks"
  type        = list(string)
  default     = []
}

variable "attach_kinesis_policy" {
  description = "Controls whether the Kinesis policy should be added to IAM role"
  type        = bool
  default     = false
}

variable "kinesis_target_arns" {
  description = "The ARNs of the Kinesis Streams to use as EventBridge targets"
  type        = list(string)
  default     = []
}

variable "attach_kinesis_firehose_policy" {
  description = "Controls whether the Kinesis Firehose policy should be added to IAM role"
  type        = bool
  default     = false
}

variable "kinesis_firehose_target_arns" {
  description = "The ARNs of the Kinesis Firehose Delivery Streams to use as EventBridge targets"
  type        = list(string)
  default     = []
}

variable "attach_lambda_policy" {
  description = "Controls whether the Lambda Function policy should be added to IAM role"
  type        = bool
  default     = false
}

variable "lambda_target_arns" {
  description = "The ARNs of the Lambda Functions to use as EventBridge targets"
  type        = list(string)
  default     = []
}

variable "attach_sfn_policy" {
  description = "Controls whether the Step Functions policy should be added to IAM role"
  type        = bool
  default     = false
}

variable "sfn_target_arns" {
  description = "The ARNs of the Step Functions state machines to use as EventBridge targets"
  type        = list(string)
  default     = []
}

variable "attach_sqs_policy" {
  description = "Controls whether the SQS policy should be added to IAM role"
  type        = bool
  default     = false
}

variable "sqs_target_arns" {
  description = "The ARNs of the SQS queues to use as EventBridge targets"
  type        = list(string)
  default     = []
}

variable "attach_sns_policy" {
  description = "Controls whether the SNS policy should be added to IAM role"
  type        = bool
  default     = false
}

variable "sns_target_arns" {
  description = "The ARNs of the SNS topics to use as EventBridge targets"
  type        = list(string)
  default     = []
}

variable "attach_api_destination_policy" {
  description = "Controls whether the API Destination policy should be added to IAM role"
  type        = bool
  default     = false
}

variable "attach_tracing_policy" {
  description = "Controls whether X-Ray tracing policy should be added to IAM role"
  type        = bool
  default     = false
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

# Naming postfixes
variable "append_rule_postfix" {
  description = "Controls whether to append '-rule' to the name of the rule"
  type        = bool
  default     = true
}

variable "append_connection_postfix" {
  description = "Controls whether to append '-connection' to the name of the connection"
  type        = bool
  default     = true
}

variable "append_destination_postfix" {
  description = "Controls whether to append '-destination' to the name of the destination"
  type        = bool
  default     = true
}

variable "append_schedule_postfix" {
  description = "Controls whether to append '-schedule' to the name of the schedule"
  type        = bool
  default     = true
}

variable "append_schedule_group_postfix" {
  description = "Controls whether to append '-group' to the name of the schedule group"
  type        = bool
  default     = true
}

variable "append_pipe_postfix" {
  description = "Controls whether to append '-pipe' to the name of the pipe"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Additional tags to merge with common tags"
  type        = map(string)
  default     = {}
}
