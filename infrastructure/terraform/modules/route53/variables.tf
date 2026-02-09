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
  description = "Domain name for the hosted zone"
  type        = string
}

variable "create_hosted_zone" {
  description = "Whether to create a new hosted zone or use an existing one"
  type        = bool
  default     = false
}

variable "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  type        = string
}

variable "alb_zone_id" {
  description = "Zone ID of the Application Load Balancer"
  type        = string
}
