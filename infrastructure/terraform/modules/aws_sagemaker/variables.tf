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
  description = "Name identifier for the notebook instance"
  type        = string
}

variable "instance_type" {
  description = "SageMaker notebook instance type"
  type        = string
  default     = "ml.t3.medium"
}

variable "volume_size" {
  description = "EBS volume size in GB"
  type        = number
  default     = 20
}

variable "subnet_id" {
  description = "Subnet ID for VPC placement"
  type        = string
  default     = null
}

variable "security_group_ids" {
  description = "List of security group IDs"
  type        = list(string)
  default     = []
}

variable "kms_key_id" {
  description = "KMS key ID for encryption at rest"
  type        = string
  default     = null
}

variable "direct_internet_access" {
  description = "Whether the notebook has direct internet access"
  type        = bool
  default     = false
}

variable "auto_stop_idle_minutes" {
  description = "Auto-stop after N minutes of idle time. Set to 0 to disable"
  type        = number
  default     = 60
}

variable "attach_full_access_policy" {
  description = "Attach AmazonSageMakerFullAccess managed policy"
  type        = bool
  default     = true
}

variable "additional_policy_arns" {
  description = "Additional IAM policy ARNs to attach to the SageMaker role"
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Additional tags to merge with common tags"
  type        = map(string)
  default     = {}
}
