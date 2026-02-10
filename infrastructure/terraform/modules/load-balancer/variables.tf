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
