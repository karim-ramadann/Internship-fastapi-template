# =============================================================================
# GitHub OIDC Module - Outputs
# =============================================================================

output "role_arn" {
  description = "ARN of the IAM role for GitHub Actions (use as role-to-assume in configure-aws-credentials)"
  value       = aws_iam_role.github_actions.arn
}

output "role_name" {
  description = "Name of the IAM role"
  value       = aws_iam_role.github_actions.name
}

output "provider_arn" {
  description = "ARN of the GitHub OIDC provider"
  value       = local.oidc_provider_arn
}
