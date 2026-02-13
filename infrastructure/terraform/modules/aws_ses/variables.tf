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
  description = "Domain name for SES identity"
  type        = string
}

variable "route53_zone_id" {
  description = "Route53 hosted zone ID for DNS verification"
  type        = string
  default     = ""
}

variable "verify_domain" {
  description = "Whether to verify the domain identity via DNS"
  type        = bool
  default     = true
}

variable "verify_dkim" {
  description = "Whether to verify DKIM for the domain"
  type        = bool
  default     = true
}

variable "create_configuration_set" {
  description = "Whether to create an SES configuration set"
  type        = bool
  default     = true
}

variable "mail_from_subdomain" {
  description = "Subdomain for MAIL FROM (e.g., 'mail' creates mail.domain.com)"
  type        = string
  default     = "mail"
}

variable "email_identities" {
  description = "Map of email identities to create"
  type        = any
  default     = {}
}

variable "templates" {
  description = "Map of SES email templates"
  type        = any
  default     = {}
}

variable "tags" {
  description = "Additional tags to merge with common tags"
  type        = map(string)
  default     = {}
}
