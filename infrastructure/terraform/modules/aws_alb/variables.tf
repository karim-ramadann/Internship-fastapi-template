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
  description = "Name identifier for the ALB (will be prefixed with project-environment)"
  type        = string
  default     = "alb"
}

variable "load_balancer_type" {
  description = "The type of load balancer to create. Possible values are application, gateway, or network"
  type        = string
  default     = "application"
}

variable "internal" {
  description = "Boolean determining if the load balancer is internal or externally facing"
  type        = bool
  default     = false
}

# Networking
variable "vpc_id" {
  description = "VPC ID where the load balancer will be deployed"
  type        = string
}

variable "subnets" {
  description = "List of subnet IDs to attach to the load balancer"
  type        = list(string)
}

variable "security_groups" {
  description = "List of security group IDs to assign to the load balancer"
  type        = list(string)
  default     = []
}

# Deletion Protection
variable "enable_deletion_protection" {
  description = "If true, deletion of the load balancer will be disabled via the AWS API"
  type        = bool
  default     = false
}

# Load Balancing Configuration
variable "enable_cross_zone_load_balancing" {
  description = "If true, cross-zone load balancing of the load balancer will be enabled"
  type        = bool
  default     = true
}

# HTTP Configuration
variable "enable_http2" {
  description = "Indicates whether HTTP/2 is enabled in application load balancers"
  type        = bool
  default     = true
}

variable "enable_waf_fail_open" {
  description = "Indicates whether to allow a WAF-enabled load balancer to route requests to targets if it is unable to forward the request to AWS WAF"
  type        = bool
  default     = false
}

variable "enable_xff_client_port" {
  description = "Indicates whether the X-Forwarded-For header should preserve the source port that the client used to connect to the load balancer"
  type        = bool
  default     = false
}

variable "preserve_host_header" {
  description = "Indicates whether the Application Load Balancer should preserve the Host header in the HTTP request and send it to the target without any change"
  type        = bool
  default     = false
}

variable "xff_header_processing_mode" {
  description = "Determines how the load balancer modifies the X-Forwarded-For header. Valid values: append, preserve, remove"
  type        = string
  default     = "append"
}

variable "desync_mitigation_mode" {
  description = "Determines how the load balancer handles requests that might pose a security risk. Valid values: monitor, defensive, strictest"
  type        = string
  default     = "defensive"
}

variable "drop_invalid_header_fields" {
  description = "Indicates whether HTTP headers with header fields that are not valid are removed by the load balancer (true) or routed to targets (false)"
  type        = bool
  default     = true
}

variable "idle_timeout" {
  description = "The time in seconds that the connection is allowed to be idle"
  type        = number
  default     = 60
}

variable "ip_address_type" {
  description = "The type of IP addresses used by the subnets for your load balancer. Valid values: ipv4, dualstack"
  type        = string
  default     = "ipv4"
}

# Access Logs
variable "access_logs" {
  description = "Map containing access logging configuration for load balancer"
  type = object({
    bucket  = string
    enabled = optional(bool, true)
    prefix  = optional(string)
  })
  default = null
}

# Connection Logs
variable "connection_logs" {
  description = "Map containing connection logging configuration for load balancer"
  type = object({
    bucket  = string
    enabled = optional(bool, true)
    prefix  = optional(string)
  })
  default = null
}

# Target Groups
variable "target_groups" {
  description = "Map of target group configurations"
  type        = any
  default     = {}
}

# Listeners
variable "listeners" {
  description = "Map of listener configurations"
  type        = any
  default     = {}
}

# Listener Rules
variable "listener_rules" {
  description = "Map of listener rule configurations"
  type        = any
  default     = {}
}

# Route53
variable "route53_records" {
  description = "Map of Route53 records to create for the load balancer"
  type        = any
  default     = {}
}

# WAF
variable "web_acl_arn" {
  description = "ARN of the Web Application Firewall (WAF) to associate with the load balancer"
  type        = string
  default     = null
}

# Tags
variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}
