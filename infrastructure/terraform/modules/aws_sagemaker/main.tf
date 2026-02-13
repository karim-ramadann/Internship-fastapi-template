/**
 * # SageMaker Module
 *
 * Native Terraform resources for AWS SageMaker notebook instances.
 *
 * Standards enforced:
 * - Naming convention: `{project}-{name}-{environment}`
 * - VPC placement in private subnets
 * - Encryption at rest via KMS
 * - Auto-stop lifecycle configuration for cost control
 * - Standard tagging
 */

locals {
  notebook_name = "${var.context.project}-${var.name}-${var.context.environment}"

  tags = merge(
    var.context.common_tags,
    {
      Name      = local.notebook_name
      Component = "sagemaker"
    },
    var.tags
  )
}

# IAM role for SageMaker
resource "aws_iam_role" "sagemaker" {
  name = "${local.notebook_name}-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "sagemaker.amazonaws.com"
        }
      }
    ]
  })

  tags = local.tags
}

resource "aws_iam_role_policy_attachment" "sagemaker_full_access" {
  count      = var.attach_full_access_policy ? 1 : 0
  role       = aws_iam_role.sagemaker.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSageMakerFullAccess"
}

resource "aws_iam_role_policy_attachment" "custom_policies" {
  for_each   = toset(var.additional_policy_arns)
  role       = aws_iam_role.sagemaker.name
  policy_arn = each.value
}

# Lifecycle configuration for auto-stop
resource "aws_sagemaker_notebook_instance_lifecycle_configuration" "auto_stop" {
  count = var.auto_stop_idle_minutes > 0 ? 1 : 0

  name = "${local.notebook_name}-auto-stop"

  on_start = base64encode(<<-EOF
    #!/bin/bash
    set -e
    IDLE_TIME=${var.auto_stop_idle_minutes * 60}
    echo "Auto-stop configured for $IDLE_TIME seconds of idle time"
    # Install auto-stop script
    wget -O /usr/local/bin/autostop.py https://raw.githubusercontent.com/aws-samples/amazon-sagemaker-notebook-instance-lifecycle-config-samples/master/scripts/auto-stop-idle/autostop.py
    (crontab -l 2>/dev/null; echo "*/5 * * * * /usr/bin/python3 /usr/local/bin/autostop.py --time $IDLE_TIME --ignore-connections") | crontab -
  EOF
  )
}

# Notebook instance
resource "aws_sagemaker_notebook_instance" "this" {
  name          = local.notebook_name
  role_arn      = aws_iam_role.sagemaker.arn
  instance_type = var.instance_type

  # Network
  subnet_id       = var.subnet_id
  security_groups = var.security_group_ids

  # Encryption
  kms_key_id = var.kms_key_id

  # Storage
  volume_size = var.volume_size

  # Lifecycle
  lifecycle_config_name = var.auto_stop_idle_minutes > 0 ? aws_sagemaker_notebook_instance_lifecycle_configuration.auto_stop[0].name : null

  # Direct internet access
  direct_internet_access = var.direct_internet_access ? "Enabled" : "Disabled"

  tags = local.tags
}
