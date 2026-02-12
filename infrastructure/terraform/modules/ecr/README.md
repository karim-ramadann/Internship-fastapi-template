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
