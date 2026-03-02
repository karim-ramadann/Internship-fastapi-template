<!-- BEGIN_TF_DOCS -->
# ECR Repository Module

Thin wrapper around [terraform-aws-modules/ecr/aws](https://registry.terraform.io/modules/terraform-aws-modules/ecr/aws/latest).

This module provides organization-wide standards for ECR repositories:
- Standard naming and tagging conventions
- Image scanning on push
- Lifecycle policies for image retention
- Encryption configuration (AES256 or KMS)
- Repository policies for access control

## What This Module Adds

This wrapper module provides organization-wide standards:

- **Naming convention**: `{project}-{environment}-{resource_name}`
- **Standard tagging**: Merges project, environment, and component tags
- **Environment-based defaults**: Configures resources based on environment (production vs staging)

## Usage

```hcl
module "example" {
  source = "./modules/MODULE_NAME"

  context = local.context

  # Module-specific variables
}
```

## Requirements

No requirements.

## Providers

No providers.

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_ecr"></a> [ecr](#module\_ecr) | terraform-aws-modules/ecr/aws | ~> 3.0 |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_context"></a> [context](#input\_context) | Context object containing project, environment, region, and common tags | <pre>object({<br/>    project     = string<br/>    environment = string<br/>    region      = string<br/>    common_tags = map(string)<br/>  })</pre> | n/a | yes |
| <a name="input_name"></a> [name](#input\_name) | Name identifier for the ECR repository (will be prefixed with project-environment) | `string` | n/a | yes |
| <a name="input_create_lifecycle_policy"></a> [create\_lifecycle\_policy](#input\_create\_lifecycle\_policy) | Determines whether a lifecycle policy will be created | `bool` | `true` | no |
| <a name="input_create_repository_policy"></a> [create\_repository\_policy](#input\_create\_repository\_policy) | Determines whether a repository policy will be created | `bool` | `false` | no |
| <a name="input_encryption_type"></a> [encryption\_type](#input\_encryption\_type) | The encryption type for the repository. Must be one of: KMS or AES256 | `string` | `"AES256"` | no |
| <a name="input_force_delete"></a> [force\_delete](#input\_force\_delete) | If true, will delete the repository even if it contains images | `bool` | `false` | no |
| <a name="input_image_scan_on_push"></a> [image\_scan\_on\_push](#input\_image\_scan\_on\_push) | Indicates whether images are scanned after being pushed to the repository | `bool` | `true` | no |
| <a name="input_image_tag_mutability"></a> [image\_tag\_mutability](#input\_image\_tag\_mutability) | The tag mutability setting for the repository. Must be one of: MUTABLE or IMMUTABLE | `string` | `"MUTABLE"` | no |
| <a name="input_kms_key_arn"></a> [kms\_key\_arn](#input\_kms\_key\_arn) | The ARN of the KMS key to use when encryption\_type is KMS | `string` | `null` | no |
| <a name="input_lambda_read_access_arns"></a> [lambda\_read\_access\_arns](#input\_lambda\_read\_access\_arns) | The ARNs of the Lambda service roles that have read access to the repository | `list(string)` | `[]` | no |
| <a name="input_lifecycle_policy"></a> [lifecycle\_policy](#input\_lifecycle\_policy) | The policy document for lifecycle management (JSON formatted string) | `string` | `null` | no |
| <a name="input_public_repository_catalog_data"></a> [public\_repository\_catalog\_data](#input\_public\_repository\_catalog\_data) | Catalog data configuration for public repositories | <pre>object({<br/>    about_text        = optional(string)<br/>    architectures     = optional(list(string))<br/>    description       = optional(string)<br/>    logo_image_blob   = optional(string)<br/>    operating_systems = optional(list(string))<br/>    usage_text        = optional(string)<br/>  })</pre> | `null` | no |
| <a name="input_read_access_arns"></a> [read\_access\_arns](#input\_read\_access\_arns) | The ARNs of the IAM users/roles that have read access to the repository | `list(string)` | `[]` | no |
| <a name="input_read_write_access_arns"></a> [read\_write\_access\_arns](#input\_read\_write\_access\_arns) | The ARNs of the IAM users/roles that have read/write access to the repository | `list(string)` | `[]` | no |
| <a name="input_repository_policy"></a> [repository\_policy](#input\_repository\_policy) | The JSON policy to apply to the repository | `string` | `null` | no |
| <a name="input_repository_type"></a> [repository\_type](#input\_repository\_type) | The type of repository to create. Either public or private | `string` | `"private"` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Additional tags to merge with common tags | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_repository_arn"></a> [repository\_arn](#output\_repository\_arn) | Full ARN of the repository |
| <a name="output_repository_name"></a> [repository\_name](#output\_repository\_name) | Name of the repository |
| <a name="output_repository_registry_id"></a> [repository\_registry\_id](#output\_repository\_registry\_id) | The registry ID where the repository was created |
| <a name="output_repository_url"></a> [repository\_url](#output\_repository\_url) | The URL of the repository (in the form aws\_account\_id.dkr.ecr.region.amazonaws.com/repositoryName) |
<!-- END_TF_DOCS -->
