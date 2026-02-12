# ECR Module

Creates ECR repositories for backend and frontend container images.

## What it does

- Creates `backend` and `frontend` ECR repositories with image scanning on push
- Configures lifecycle policies: keeps last 10 environment-tagged images, expires untagged images after 14 days
- AES256 encryption at rest

## Usage

```hcl
module "ecr" {
  source = "./modules/ecr"

  context = local.context
}
```

## Inputs

See [variables.tf](./variables.tf) for the full list.

## Outputs

See [outputs.tf](./outputs.tf) for the full list.

<!-- BEGIN_TF_DOCS -->
# ECR Module

Creates ECR repositories for backend and frontend container images.

## What it does

- Creates `backend` and `frontend` ECR repositories with image scanning on push
- Configures lifecycle policies: keeps last 10 environment-tagged images, expires untagged images after 14 days
- AES256 encryption at rest

## Usage

```hcl
module "ecr" {
  source = "./modules/ecr"

  context = local.context
}
```

## Inputs

See [variables.tf](./variables.tf) for the full list.

## Outputs

See [outputs.tf](./outputs.tf) for the full list.

## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_ecr_lifecycle_policy.backend](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecr_lifecycle_policy) | resource |
| [aws_ecr_lifecycle_policy.frontend](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecr_lifecycle_policy) | resource |
| [aws_ecr_repository.backend](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecr_repository) | resource |
| [aws_ecr_repository.frontend](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecr_repository) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_context"></a> [context](#input\_context) | Context object containing project, environment, region, and common tags | <pre>object({<br/>    project     = string<br/>    environment = string<br/>    region      = string<br/>    common_tags = map(string)<br/>  })</pre> | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_backend_repository_arn"></a> [backend\_repository\_arn](#output\_backend\_repository\_arn) | ARN of the backend ECR repository |
| <a name="output_backend_repository_name"></a> [backend\_repository\_name](#output\_backend\_repository\_name) | Name of the backend ECR repository |
| <a name="output_backend_repository_url"></a> [backend\_repository\_url](#output\_backend\_repository\_url) | URL of the backend ECR repository |
| <a name="output_frontend_repository_arn"></a> [frontend\_repository\_arn](#output\_frontend\_repository\_arn) | ARN of the frontend ECR repository |
| <a name="output_frontend_repository_name"></a> [frontend\_repository\_name](#output\_frontend\_repository\_name) | Name of the frontend ECR repository |
| <a name="output_frontend_repository_url"></a> [frontend\_repository\_url](#output\_frontend\_repository\_url) | URL of the frontend ECR repository |
<!-- END_TF_DOCS -->