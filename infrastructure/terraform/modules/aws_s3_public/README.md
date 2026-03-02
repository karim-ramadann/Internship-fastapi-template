<!-- BEGIN_TF_DOCS -->
# S3 Public Bucket Module

Thin wrapper around [terraform-aws-modules/s3-bucket/aws](https://registry.terraform.io/modules/terraform-aws-modules/s3-bucket/aws/latest).

Standards enforced:
- Naming convention: `{project}-{name}-{environment}`
- Public read access via bucket policy
- Server-side encryption (SSE-S3) enabled
- Designed for static assets, public downloads, or website hosting

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
| <a name="module_s3_bucket"></a> [s3\_bucket](#module\_s3\_bucket) | terraform-aws-modules/s3-bucket/aws | ~> 4.0 |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_context"></a> [context](#input\_context) | Context object containing project, environment, region, and common tags | <pre>object({<br/>    project     = string<br/>    environment = string<br/>    region      = string<br/>    common_tags = map(string)<br/>  })</pre> | n/a | yes |
| <a name="input_name"></a> [name](#input\_name) | Name identifier for the bucket (will be prefixed with project-environment) | `string` | n/a | yes |
| <a name="input_cors_rules"></a> [cors\_rules](#input\_cors\_rules) | List of CORS rules | `any` | `[]` | no |
| <a name="input_enable_versioning"></a> [enable\_versioning](#input\_enable\_versioning) | Enable versioning on the bucket | `bool` | `false` | no |
| <a name="input_enable_website"></a> [enable\_website](#input\_enable\_website) | Enable static website hosting | `bool` | `false` | no |
| <a name="input_error_document"></a> [error\_document](#input\_error\_document) | Error document for website hosting | `string` | `"error.html"` | no |
| <a name="input_index_document"></a> [index\_document](#input\_index\_document) | Index document for website hosting | `string` | `"index.html"` | no |
| <a name="input_lifecycle_rules"></a> [lifecycle\_rules](#input\_lifecycle\_rules) | List of lifecycle rules | `any` | `[]` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Additional tags to merge with common tags | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_bucket_arn"></a> [bucket\_arn](#output\_bucket\_arn) | ARN of the bucket |
| <a name="output_bucket_domain_name"></a> [bucket\_domain\_name](#output\_bucket\_domain\_name) | Domain name of the bucket |
| <a name="output_bucket_id"></a> [bucket\_id](#output\_bucket\_id) | Name of the bucket |
| <a name="output_bucket_regional_domain_name"></a> [bucket\_regional\_domain\_name](#output\_bucket\_regional\_domain\_name) | Regional domain name of the bucket |
| <a name="output_bucket_website_domain"></a> [bucket\_website\_domain](#output\_bucket\_website\_domain) | Website domain of the bucket (if website hosting enabled) |
| <a name="output_bucket_website_endpoint"></a> [bucket\_website\_endpoint](#output\_bucket\_website\_endpoint) | Website endpoint of the bucket (if website hosting enabled) |
<!-- END_TF_DOCS -->
