variable "context" {
  description = "Context object containing project, environment, region, and common tags"
  type = object({
    project     = string
    environment = string
    region      = string
    common_tags = map(string)
  })
}

variable "domain" {
  description = "Primary domain name for the ACM certificate"
  type        = string
}

variable "subject_alternative_names" {
  description = "Subject Alternative Names (SANs) for the certificate. Defaults to wildcard of primary domain"
  type        = list(string)
  default     = null
}

variable "route53_zone_id" {
  description = "Route53 hosted zone ID for DNS validation records. When empty, DNS records must be created externally"
  type        = string
  default     = ""
}

variable "wait_for_validation" {
  description = "Wait for certificate validation to complete before returning. Only applies when route53_zone_id is provided"
  type        = bool
  default     = true
}

variable "validation_timeout" {
  description = "Maximum time to wait for certificate validation"
  type        = string
  default     = "45m"
}
