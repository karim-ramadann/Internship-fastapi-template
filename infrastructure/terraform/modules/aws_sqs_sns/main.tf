/**
 * # SQS + SNS Module
 *
 * Thin wrappers around:
 * - [terraform-aws-modules/sqs/aws](https://registry.terraform.io/modules/terraform-aws-modules/sqs/aws/latest)
 * - [terraform-aws-modules/sns/aws](https://registry.terraform.io/modules/terraform-aws-modules/sns/aws/latest)
 *
 * Standards enforced:
 * - Naming convention: `{project}-{name}-{environment}`
 * - Server-side encryption enabled by default
 * - Dead-letter queue support for SQS
 * - Optional SNS-to-SQS subscription wiring
 * - Standard tagging
 */

locals {
  sqs_name = "${var.context.project}-${var.name}-${var.context.environment}"
  sns_name = "${var.context.project}-${var.name}-${var.context.environment}"

  tags = merge(
    var.context.common_tags,
    {
      Name      = local.sqs_name
      Component = "messaging"
    },
    var.tags
  )
}

# ============================================================================
# SQS Queue
# ============================================================================

module "sqs" {
  source  = "terraform-aws-modules/sqs/aws"
  version = "~> 4.0"

  count = var.create_sqs ? 1 : 0

  name = local.sqs_name

  # Encryption
  sqs_managed_sse_enabled   = var.kms_key_arn == null
  kms_master_key_id         = var.kms_key_arn
  kms_data_key_reuse_period = var.kms_key_arn != null ? 300 : null

  # Queue settings
  visibility_timeout_seconds = var.visibility_timeout_seconds
  message_retention_seconds  = var.message_retention_seconds
  max_message_size           = var.max_message_size
  delay_seconds              = var.delay_seconds
  receive_wait_time_seconds  = var.receive_wait_time_seconds

  # Dead-letter queue
  redrive_policy = var.create_dlq ? jsonencode({
    deadLetterTargetArn = module.sqs_dlq[0].queue_arn
    maxReceiveCount     = var.max_receive_count
  }) : var.redrive_policy

  # FIFO
  fifo_queue                  = var.fifo_queue
  content_based_deduplication = var.content_based_deduplication

  tags = local.tags
}

# Dead-letter queue
module "sqs_dlq" {
  source  = "terraform-aws-modules/sqs/aws"
  version = "~> 4.0"

  count = var.create_sqs && var.create_dlq ? 1 : 0

  name = "${local.sqs_name}-dlq"

  sqs_managed_sse_enabled   = var.kms_key_arn == null
  kms_master_key_id         = var.kms_key_arn
  message_retention_seconds = 1209600 # 14 days for DLQ
  fifo_queue                = var.fifo_queue

  tags = merge(local.tags, { Name = "${local.sqs_name}-dlq" })
}

# ============================================================================
# SNS Topic
# ============================================================================

module "sns" {
  source  = "terraform-aws-modules/sns/aws"
  version = "~> 6.0"

  count = var.create_sns ? 1 : 0

  name = local.sns_name

  # Encryption
  kms_master_key_id = var.kms_key_arn

  # FIFO
  fifo_topic                  = var.fifo_queue
  content_based_deduplication = var.content_based_deduplication

  # Subscriptions
  subscriptions = var.sns_subscriptions

  tags = local.tags
}
