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
  description = "Domain name for the certificate (will also create *.domain wildcard)"
  type        = string
}

variable "route53_zone_id" {
  description = "Route53 zone ID for DNS validation records"
  type        = string
}
