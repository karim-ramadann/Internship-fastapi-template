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
  description = "Name identifier for the parameter (used in path: /{env}/{project}/{name})"
  type        = string
}

variable "description" {
  description = "Description of the parameter"
  type        = string
  default     = ""
}

variable "type" {
  description = "Parameter type (String, StringList, or SecureString)"
  type        = string
  default     = "SecureString"

  validation {
    condition     = contains(["String", "StringList", "SecureString"], var.type)
    error_message = "Type must be String, StringList, or SecureString."
  }
}

variable "value" {
  description = "Value of the parameter"
  type        = string
  sensitive   = true
}

variable "kms_key_id" {
  description = "KMS key ID for SecureString encryption. If null, uses the default aws/ssm key"
  type        = string
  default     = null
}

variable "tags" {
  description = "Additional tags to merge with common tags"
  type        = map(string)
  default     = {}
}
