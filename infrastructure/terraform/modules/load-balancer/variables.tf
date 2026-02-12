variable "context" {
  description = "Context object containing project, environment, region, and common tags"
  type = object({
    project     = string
    environment = string
    region      = string
    common_tags = map(string)
  })
}

variable "vpc_id" {
  description = "ID of the VPC where the load balancer will be created"
  type        = string
}

variable "subnets" {
  description = "List of subnet IDs for the load balancer"
  type        = list(string)
}

variable "security_groups" {
  description = "List of security group IDs to assign to the load balancer"
  type        = list(string)
}

variable "load_balancer_type" {
  description = "Type of load balancer to create (application, network, or gateway)"
  type        = string
  default     = "application"
}

variable "internal" {
  description = "Whether the load balancer is internal or internet-facing"
  type        = bool
  default     = false
}

variable "enable_deletion_protection" {
  description = "Enable deletion protection on the load balancer"
  type        = bool
  default     = false
}

variable "enable_http2" {
  description = "Enable HTTP/2 support"
  type        = bool
  default     = true
}

variable "enable_cross_zone_load_balancing" {
  description = "Enable cross-zone load balancing"
  type        = bool
  default     = true
}

variable "access_logs" {
  description = "Map containing access logging configuration"
  type        = map(string)
  default     = {}
}

# ------------------------------------------------------------------------------
# Certificate
# ------------------------------------------------------------------------------

variable "certificate_arn" {
  description = "ARN of the ACM certificate for HTTPS listener"
  type        = string
}

# ------------------------------------------------------------------------------
# Target Groups
# ------------------------------------------------------------------------------

variable "target_groups" {
  description = <<-EOT
    Map of target group definitions. Each key becomes part of the TG name.
    Example:
    target_groups = {
      backend = {
        port              = 8000
        protocol          = "HTTP"
        target_type       = "ip"
        health_check_path = "/api/v1/utils/health-check/"
      }
    }
  EOT
  type = map(object({
    port                = number
    protocol            = optional(string, "HTTP")
    target_type         = optional(string, "ip")
    health_check_path   = optional(string, "/")
    deregistration_delay = optional(number, 30)
  }))
  default = {}
}

# ------------------------------------------------------------------------------
# Listener Rules (host-based routing)
# ------------------------------------------------------------------------------

variable "host_rules" {
  description = <<-EOT
    Map of host-based routing rules for the HTTPS listener.
    Each key is a logical name; target_group_key must match a key in var.target_groups.
    Example:
    host_rules = {
      backend  = { host = "api.example.com",       target_group_key = "backend",  priority = 100 }
      frontend = { host = "dashboard.example.com",  target_group_key = "frontend", priority = 200 }
    }
  EOT
  type = map(object({
    host             = string
    target_group_key = string
    priority         = number
  }))
  default = {}
}
