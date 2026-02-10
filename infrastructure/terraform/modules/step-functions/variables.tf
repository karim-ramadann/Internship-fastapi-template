variable "context" {
  description = "Context object containing project, environment, region, and common tags"
  type = object({
    project     = string
    environment = string
    region      = string
    common_tags = map(string)
  })
}

variable "state_machine_name" {
  description = "Name of the Step Functions state machine (will be prefixed with project-environment)"
  type        = string
}

variable "definition" {
  description = "Amazon States Language definition of the state machine (JSON string)"
  type        = string
}

variable "type" {
  description = "Type of Step Functions state machine: STANDARD or EXPRESS"
  type        = string
  default     = "STANDARD"
  
  validation {
    condition     = contains(["STANDARD", "EXPRESS"], var.type)
    error_message = "Type must be either STANDARD or EXPRESS."
  }
}

variable "role_arn" {
  description = "IAM role ARN for Step Functions execution"
  type        = string
}

variable "log_level" {
  description = "CloudWatch Logs log level: ALL, ERROR, FATAL, or OFF"
  type        = string
  default     = "ALL"
  
  validation {
    condition     = contains(["ALL", "ERROR", "FATAL", "OFF"], var.log_level)
    error_message = "Log level must be ALL, ERROR, FATAL, or OFF."
  }
}

variable "include_execution_data" {
  description = "Include execution data in CloudWatch Logs (recommended for non-production only)"
  type        = bool
  default     = false
}

variable "cloudwatch_logs_retention_in_days" {
  description = "CloudWatch Logs retention in days (defaults to environment-based: prod=30, others=7)"
  type        = number
  default     = null
}

variable "tags" {
  description = "Additional tags for the Step Functions state machine"
  type        = map(string)
  default     = {}
}
