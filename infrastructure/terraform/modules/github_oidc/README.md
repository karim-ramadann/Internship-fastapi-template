# GitHub OIDC Module

Creates an IAM OIDC provider for GitHub Actions and an IAM role that workflows can assume (no long-lived AWS keys).

## Resources

- **aws_iam_openid_connect_provider**: `token.actions.githubusercontent.com` (one per account)
- **aws_iam_role**: Trust policy restricted to the given repository (and optional branch or environment)
- **Policies**: ECR (push/pull), S3 (Terraform state bucket), optional Terraform deploy (ECS, EC2, RDS, etc.)

## Usage

```hcl
module "github_oidc" {
  source = "../modules/github_oidc"

  repository           = "my-org/my-repo"
  role_name            = "GitHubActions-Role"
  backend_bucket_arn   = "arn:aws:s3:::my-tfstate-bucket"
  backend_bucket_prefix = "production"  # optional

  branch               = "main"        # optional: restrict to branch
  environment_claim    = "production"  # optional: restrict to GitHub environment

  ecr_repository_arns  = [module.ecr_backend.repository_arn]  # or [] for all in account
  attach_terraform_deploy_policy = true

  tags = {}
}
```

## GitHub Actions

In the repo, add secret **AWS_ROLE_ARN** with the value of `module.github_oidc.role_arn`. Then:

```yaml
- uses: aws-actions/configure-aws-credentials@v4
  with:
    role-to-assume: ${{ secrets.AWS_ROLE_ARN }}
    aws-region: eu-west-1
```

Ensure the job has `permissions: id-token: write`.
