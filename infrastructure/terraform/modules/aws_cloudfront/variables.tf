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
  description = "Name identifier for the CloudFront distribution (will be prefixed with project-environment)"
  type        = string
}

variable "comment" {
  description = "Comment for the CloudFront distribution"
  type        = string
  default     = null
}

variable "enabled" {
  description = "Whether the distribution is enabled to accept end user requests"
  type        = bool
  default     = true
}

variable "is_ipv6_enabled" {
  description = "Whether IPv6 is enabled for the distribution"
  type        = bool
  default     = true
}

variable "price_class" {
  description = "Price class for the CloudFront distribution (PriceClass_All, PriceClass_200, PriceClass_100)"
  type        = string
  default     = "PriceClass_100"
}

variable "retain_on_delete" {
  description = "Disables the distribution instead of deleting it when destroying the resource"
  type        = bool
  default     = false
}

variable "wait_for_deployment" {
  description = "Wait for the distribution status to change from InProgress to Deployed"
  type        = bool
  default     = true
}

variable "web_acl_id" {
  description = "ARN of the AWS WAF web ACL to associate with the distribution"
  type        = string
  default     = null
}

variable "origin" {
  description = "One or more origins for this distribution (list of maps)"
  type        = any
}

variable "origin_group" {
  description = "One or more origin groups for this distribution (map)"
  type        = any
  default     = {}
}

variable "default_cache_behavior" {
  description = "Default cache behavior for this distribution (map)"
  type        = any
}

variable "ordered_cache_behavior" {
  description = "Ordered list of cache behaviors resource for this distribution (list of maps)"
  type        = any
  default     = []
}

variable "viewer_certificate" {
  description = "The SSL configuration for this distribution (map)"
  type        = any
  default = {
    cloudfront_default_certificate = true
  }
}

variable "geo_restriction" {
  description = "Geographic restriction configuration (map with restriction_type and locations)"
  type        = any
  default = {
    restriction_type = "none"
    locations        = []
  }
}

variable "custom_error_response" {
  description = "One or more custom error response elements (list of maps)"
  type        = any
  default     = []
}

variable "logging_config" {
  description = "Logging configuration for the distribution (map with bucket, include_cookies, prefix)"
  type        = any
  default     = {}
}

variable "default_root_object" {
  description = "Object that you want CloudFront to return when a user requests the root URL"
  type        = string
  default     = "index.html"
}

variable "aliases" {
  description = "Extra CNAMEs (alternate domain names) for this distribution"
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Additional tags to merge with common tags"
  type        = map(string)
  default     = {}
}
