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
  description = "Name identifier for the queue/topic (will be prefixed with project-environment)"
  type        = string
}

# ============================================================================
# Feature flags
# ============================================================================

variable "create_sqs" {
  description = "Whether to create the SQS queue"
  type        = bool
  default     = true
}

variable "create_sns" {
  description = "Whether to create the SNS topic"
  type        = bool
  default     = false
}

variable "create_dlq" {
  description = "Whether to create a dead-letter queue for SQS"
  type        = bool
  default     = true
}

# ============================================================================
# Encryption
# ============================================================================

variable "kms_key_arn" {
  description = "ARN of KMS key for encryption. If null, uses SQS-managed SSE"
  type        = string
  default     = null
}

# ============================================================================
# SQS settings
# ============================================================================

variable "visibility_timeout_seconds" {
  description = "Visibility timeout for the queue in seconds"
  type        = number
  default     = 30
}

variable "message_retention_seconds" {
  description = "Message retention period in seconds"
  type        = number
  default     = 345600 # 4 days
}

variable "max_message_size" {
  description = "Maximum message size in bytes"
  type        = number
  default     = 262144 # 256 KB
}

variable "delay_seconds" {
  description = "Delay for messages in seconds"
  type        = number
  default     = 0
}

variable "receive_wait_time_seconds" {
  description = "Wait time for long polling in seconds"
  type        = number
  default     = 10
}

variable "max_receive_count" {
  description = "Max receive count before sending to DLQ"
  type        = number
  default     = 3
}

variable "redrive_policy" {
  description = "Custom redrive policy JSON (overrides create_dlq)"
  type        = string
  default     = null
}

# ============================================================================
# FIFO settings
# ============================================================================

variable "fifo_queue" {
  description = "Whether to create a FIFO queue/topic"
  type        = bool
  default     = false
}

variable "content_based_deduplication" {
  description = "Enable content-based deduplication for FIFO"
  type        = bool
  default     = false
}

# ============================================================================
# SNS settings
# ============================================================================

variable "sns_subscriptions" {
  description = "Map of SNS subscriptions"
  type        = any
  default     = {}
}

# ============================================================================
# Tags
# ============================================================================

variable "tags" {
  description = "Additional tags to merge with common tags"
  type        = map(string)
  default     = {}
}
