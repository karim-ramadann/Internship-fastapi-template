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
  description = "Name identifier for the bucket (will be prefixed with project-environment)"
  type        = string
}

variable "enable_versioning" {
  description = "Enable versioning on the bucket"
  type        = bool
  default     = true
}

variable "kms_key_arn" {
  description = "ARN of KMS key for encryption. If null, uses SSE-S3 (AES256)"
  type        = string
  default     = null
}

variable "lifecycle_rules" {
  description = "List of lifecycle rules"
  type        = any
  default     = []
}

variable "cors_rules" {
  description = "List of CORS rules"
  type        = any
  default     = []
}

variable "logging" {
  description = "Logging configuration"
  type        = map(string)
  default     = {}
}

variable "tags" {
  description = "Additional tags to merge with common tags"
  type        = map(string)
  default     = {}
}
