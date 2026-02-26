# =============================================================================
# GitHub OIDC Module - Variables
# =============================================================================

variable "repository" {
  description = "GitHub repository in format org/repo"
  type        = string
}

variable "create_oidc_provider" {
  description = "Create the GitHub OIDC provider (set false if another env already created it in this account)"
  type        = bool
  default     = true
}

variable "oidc_provider_arn" {
  description = "ARN of existing OIDC provider (required when create_oidc_provider is false)"
  type        = string
  default     = null
}

variable "role_name" {
  description = "Name of the IAM role for GitHub Actions"
  type        = string
}

variable "backend_bucket_arn" {
  description = "ARN of the S3 bucket used for Terraform state"
  type        = string
}

variable "backend_bucket_prefix" {
  description = "Optional key prefix for state objects (e.g. env path)"
  type        = string
  default     = ""
}

variable "branch" {
  description = "Optional branch restriction (e.g. main). Empty = any ref"
  type        = string
  default     = ""
}

variable "environment_claim" {
  description = "Optional GitHub environment name to restrict (e.g. production)"
  type        = string
  default     = ""
}

variable "ecr_repository_arns" {
  description = "List of ECR repository ARNs the role can push to. Empty = allow all in account"
  type        = list(string)
  default     = []
}

variable "attach_terraform_deploy_policy" {
  description = "Attach policy allowing Terraform to manage common resources (ECS, EC2, RDS, etc.)"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags to apply to created resources"
  type        = map(string)
  default     = {}
}
