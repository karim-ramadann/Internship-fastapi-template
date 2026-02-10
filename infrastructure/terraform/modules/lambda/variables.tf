variable "context" {
  description = "Context object containing project, environment, region, and common tags"
  type = object({
    project     = string
    environment = string
    region      = string
    common_tags = map(string)
  })
}

variable "function_name" {
  description = "Unique name for this Lambda function (will be prefixed with project-environment)"
  type        = string
}

variable "description" {
  description = "Description of the Lambda function"
  type        = string
  default     = ""
}

variable "handler" {
  description = "Lambda function handler (for Zip packages)"
  type        = string
  default     = "index.handler"
}

variable "runtime" {
  description = "Lambda runtime (e.g., python3.11, nodejs20.x)"
  type        = string
  default     = "python3.11"
}

variable "timeout" {
  description = "Function timeout in seconds"
  type        = number
  default     = 300
}

variable "memory_size" {
  description = "Amount of memory in MB available to the function"
  type        = number
  default     = 1024
}

variable "lambda_role" {
  description = "IAM role ARN for Lambda execution"
  type        = string
}

variable "vpc_subnet_ids" {
  description = "List of subnet IDs for VPC configuration"
  type        = list(string)
  default     = []
}

variable "vpc_security_group_ids" {
  description = "List of security group IDs for VPC configuration"
  type        = list(string)
  default     = []
}

variable "environment_variables" {
  description = "Map of environment variables for the Lambda function"
  type        = map(string)
  default     = {}
}

variable "cloudwatch_logs_retention_in_days" {
  description = "CloudWatch Logs retention in days (defaults to environment-based: prod=30, others=7)"
  type        = number
  default     = null
}

variable "create_package" {
  description = "Whether to create a deployment package"
  type        = bool
  default     = false
}

variable "local_existing_package" {
  description = "Path to an existing local deployment package"
  type        = string
  default     = null
}

variable "image_uri" {
  description = "ECR image URI for container-based Lambda (recommended for complex dependencies)"
  type        = string
  default     = null
}

variable "package_type" {
  description = "Lambda deployment package type: Zip or Image"
  type        = string
  default     = "Zip"
}

variable "attach_policy_statements" {
  description = "Whether to attach additional IAM policy statements"
  type        = bool
  default     = false
}

variable "policy_statements" {
  description = "Map of IAM policy statements to attach to the Lambda role"
  type        = any
  default     = {}
}

variable "tags" {
  description = "Additional tags for the Lambda function"
  type        = map(string)
  default     = {}
}
