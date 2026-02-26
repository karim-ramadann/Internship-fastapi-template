# =============================================================================
# GitHub OIDC - IAM role for GitHub Actions (build, push, deploy)
# =============================================================================
# Creates an OIDC provider and role so workflows can assume role without
# long-lived keys. Set github_repository in tfvars to enable.
# =============================================================================

data "aws_s3_bucket" "state" {
  count  = var.github_repository != "" ? 1 : 0
  bucket = var.tfstate_bucket_name
}

module "github_oidc" {
  count  = var.github_repository != "" ? 1 : 0
  source = "../modules/github_oidc"

  repository            = var.github_repository
  role_name             = "GitHubActions-${var.project}-${var.environment}"
  backend_bucket_arn    = data.aws_s3_bucket.state[0].arn
  backend_bucket_prefix = local.tfstate_key_prefix

  create_oidc_provider = var.github_oidc_create_provider
  oidc_provider_arn    = var.github_oidc_create_provider ? null : "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/token.actions.githubusercontent.com"

  branch            = var.github_oidc_branch
  environment_claim = var.github_oidc_environment

  ecr_repository_arns            = [module.ecr_backend.repository_arn]
  attach_terraform_deploy_policy = true

  tags = var.common_tags
}
