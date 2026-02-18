# ============================================================================
# ECR Repository for Backend Docker Images
# ============================================================================

module "ecr_backend" {
  source = "../modules/aws_ecr_repository"

  context = local.context
  name    = var.ecr_repository_name

  # Repository configuration
  repository_type      = "private"
  image_tag_mutability = "IMMUTABLE"
  image_scan_on_push   = true
  force_delete         = var.environment != "production" # Allow force delete for non-prod
  encryption_type      = "KMS"

  # Lifecycle policy to keep only the last 10 images
  create_lifecycle_policy = true
  lifecycle_policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last 10 images"
        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = 10
        }
        action = {
          type = "expire"
        }
      }
    ]
  })

  tags = {
    Component = "container-registry"
  }
}
