/**
 * # ECR Repository Module
 *
 * Thin wrapper around [terraform-aws-modules/ecr/aws](https://registry.terraform.io/modules/terraform-aws-modules/ecr/aws/latest).
 *
 * This module provides organization-wide standards for ECR repositories:
 * - Standard naming and tagging conventions
 * - Image scanning on push
 * - Lifecycle policies for image retention
 * - Encryption configuration (AES256 or KMS)
 * - Repository policies for access control
 */

locals {
  # Naming standard: project-resource-name-env (flat)
  repository_name = "${var.context.project}-${var.name}-${var.context.environment}"

  tags = merge(
    var.context.common_tags,
    {
      Name      = local.repository_name
      Component = "ecr"
    },
    var.tags
  )
}

module "ecr" {
  source  = "terraform-aws-modules/ecr/aws"
  version = "~> 3.0"

  repository_name = local.repository_name
  repository_type = var.repository_type

  # Repository configuration
  repository_image_tag_mutability = var.image_tag_mutability
  repository_image_scan_on_push   = var.image_scan_on_push
  repository_force_delete         = var.force_delete

  # Encryption configuration
  repository_encryption_type = var.encryption_type
  repository_kms_key         = var.kms_key_arn

  # Lifecycle policy
  create_lifecycle_policy     = var.create_lifecycle_policy
  repository_lifecycle_policy = var.lifecycle_policy

  # Repository policy
  attach_repository_policy = var.create_repository_policy || var.repository_policy != null
  create_repository_policy = var.create_repository_policy
  repository_policy        = var.repository_policy

  # Access control via IAM
  repository_read_access_arns        = length(var.read_access_arns) > 0 ? var.read_access_arns : []
  repository_read_write_access_arns  = length(var.read_write_access_arns) > 0 ? var.read_write_access_arns : []
  repository_lambda_read_access_arns = length(var.lambda_read_access_arns) > 0 ? var.lambda_read_access_arns : []

  # Public repository catalog data (only for public repositories)
  public_repository_catalog_data = var.public_repository_catalog_data

  tags = local.tags
}
