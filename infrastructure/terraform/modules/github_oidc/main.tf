# =============================================================================
# GitHub OIDC Module - IAM provider and role for GitHub Actions
# =============================================================================

locals {
  oidc_provider_url = "token.actions.githubusercontent.com"
  # Use existing provider ARN or the one we create
  oidc_provider_arn = var.create_oidc_provider ? aws_iam_openid_connect_provider.github[0].arn : var.oidc_provider_arn

  # Build sub claims list: branch-based + environment-based claims
  # Supports both branch refs and GitHub environment deployments
  oidc_sub_claims = concat(
    var.branch != "" ? ["repo:${var.repository}:ref:refs/heads/${var.branch}"] : ["repo:${var.repository}:*"],
    [for env in var.environment_claims : "repo:${var.repository}:environment:${env}"]
  )
}

# GitHub OIDC provider (create once per account; set create_oidc_provider = false in other envs)
resource "aws_iam_openid_connect_provider" "github" {
  count = var.create_oidc_provider ? 1 : 0

  url             = "https://${local.oidc_provider_url}"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]

  tags = var.tags
}

# IAM role assumable by GitHub Actions via OIDC
resource "aws_iam_role" "github_actions" {
  name        = var.role_name
  description = "Role for GitHub Actions (OIDC) - ${var.repository}"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = local.oidc_provider_arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${local.oidc_provider_url}:aud" = "sts.amazonaws.com"
          }
          "ForAnyValue:StringLike" = {
            "${local.oidc_provider_url}:sub" = local.oidc_sub_claims
          }
        }
      }
    ]
  })

  tags = var.tags
}

# ECR policy: GetAuthorizationToken + push to specified repos (or all)
locals {
  ecr_resources = length(var.ecr_repository_arns) > 0 ? var.ecr_repository_arns : ["*"]
}

resource "aws_iam_role_policy" "ecr" {
  name = "${var.role_name}-ecr"
  role = aws_iam_role.github_actions.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ECRAuth"
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken"
        ]
        Resource = "*"
      },
      {
        Sid    = "ECRPush"
        Effect = "Allow"
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:PutImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload"
        ]
        Resource = local.ecr_resources
      }
    ]
  })
}

# S3 policy: read/write Terraform state bucket
resource "aws_iam_role_policy" "s3_state" {
  name = "${var.role_name}-s3-state"
  role = aws_iam_role.github_actions.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "S3ListBucket"
        Effect = "Allow"
        Action = [
          "s3:ListBucket"
        ]
        Resource = [var.backend_bucket_arn]
      },
      {
        Sid    = "S3StateObject"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ]
        Resource = [var.backend_bucket_prefix != "" ? "${var.backend_bucket_arn}/${var.backend_bucket_prefix}/*" : "${var.backend_bucket_arn}/*"]
      }
    ]
  })
}

# Optional: broad policy so this role can run Terraform plan/apply (ECS, ECR, VPC, RDS, etc.)
resource "aws_iam_role_policy" "terraform_deploy" {
  count = var.attach_terraform_deploy_policy ? 1 : 0

  name = "${var.role_name}-terraform-deploy"
  role = aws_iam_role.github_actions.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "TerraformEC2"
        Effect = "Allow"
        Action = [
          "ec2:*"
        ]
        Resource = "*"
      },
      {
        Sid    = "TerraformELB"
        Effect = "Allow"
        Action = [
          "elasticloadbalancing:*"
        ]
        Resource = "*"
      },
      {
        Sid    = "TerraformECS"
        Effect = "Allow"
        Action = [
          "ecs:*"
        ]
        Resource = "*"
      },
      {
        Sid    = "TerraformRDS"
        Effect = "Allow"
        Action = [
          "rds:*"
        ]
        Resource = "*"
      },
      {
        Sid    = "TerraformSecrets"
        Effect = "Allow"
        Action = [
          "secretsmanager:*"
        ]
        Resource = "*"
      },
      {
        Sid    = "TerraformSSM"
        Effect = "Allow"
        Action = [
          "ssm:*"
        ]
        Resource = "*"
      },
      {
        Sid    = "TerraformLogs"
        Effect = "Allow"
        Action = [
          "logs:*"
        ]
        Resource = "*"
      },
      {
        Sid    = "TerraformACM"
        Effect = "Allow"
        Action = [
          "acm:*"
        ]
        Resource = "*"
      },
      {
        Sid    = "TerraformIAMPassRole"
        Effect = "Allow"
        Action = [
          "iam:PassRole",
          "iam:CreateServiceLinkedRole"
        ]
        Resource = "*"
      }
    ]
  })
}
