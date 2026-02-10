variable "context" {
  description = "Context object containing project, environment, region, and common tags"
  type = object({
    project     = string
    environment = string
    region      = string
    common_tags = map(string)
  })
}

variable "create_bus" {
  description = "Whether to create a custom EventBridge event bus"
  type        = bool
  default     = false
}

variable "bus_name" {
  description = "Name of the EventBridge event bus (will be prefixed if creating custom bus)"
  type        = string
  default     = "default"
}

variable "rules" {
  description = "Map of EventBridge rules configuration (mirrors terraform-aws-modules/eventbridge)"
  type        = any
  default     = {}
}

variable "targets" {
  description = "Map of EventBridge targets configuration (mirrors terraform-aws-modules/eventbridge)"
  type        = any
  default     = {}
}

variable "tags" {
  description = "Additional tags for EventBridge resources"
  type        = map(string)
  default     = {}
}
