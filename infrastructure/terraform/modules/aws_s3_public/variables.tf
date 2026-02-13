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
  default     = false
}

variable "enable_website" {
  description = "Enable static website hosting"
  type        = bool
  default     = false
}

variable "index_document" {
  description = "Index document for website hosting"
  type        = string
  default     = "index.html"
}

variable "error_document" {
  description = "Error document for website hosting"
  type        = string
  default     = "error.html"
}

variable "cors_rules" {
  description = "List of CORS rules"
  type        = any
  default     = []
}

variable "lifecycle_rules" {
  description = "List of lifecycle rules"
  type        = any
  default     = []
}

variable "tags" {
  description = "Additional tags to merge with common tags"
  type        = map(string)
  default     = {}
}
