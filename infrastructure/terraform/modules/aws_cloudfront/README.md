<!-- BEGIN_TF_DOCS -->
# CloudFront Distribution Module

Thin wrapper around [terraform-aws-modules/cloudfront/aws](https://registry.terraform.io/modules/terraform-aws-modules/cloudfront/aws/latest).

This module provides organization-wide standards for CloudFront distributions:
- Standard naming and tagging conventions
- Security headers via response headers policy
- Origin access control for S3 origins
- Price class configuration
- SSL/TLS certificate integration
- Custom error responses and caching behavior

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
| <a name="module_cloudfront"></a> [cloudfront](#module\_cloudfront) | terraform-aws-modules/cloudfront/aws | ~> 6.0 |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_context"></a> [context](#input\_context) | Context object containing project, environment, region, and common tags | <pre>object({<br/>    project     = string<br/>    environment = string<br/>    region      = string<br/>    common_tags = map(string)<br/>  })</pre> | n/a | yes |
| <a name="input_default_cache_behavior"></a> [default\_cache\_behavior](#input\_default\_cache\_behavior) | Default cache behavior for this distribution (map) | `any` | n/a | yes |
| <a name="input_name"></a> [name](#input\_name) | Name identifier for the CloudFront distribution (will be prefixed with project-environment) | `string` | n/a | yes |
| <a name="input_origin"></a> [origin](#input\_origin) | One or more origins for this distribution (list of maps) | `any` | n/a | yes |
| <a name="input_aliases"></a> [aliases](#input\_aliases) | Extra CNAMEs (alternate domain names) for this distribution | `list(string)` | `[]` | no |
| <a name="input_comment"></a> [comment](#input\_comment) | Comment for the CloudFront distribution | `string` | `null` | no |
| <a name="input_custom_error_response"></a> [custom\_error\_response](#input\_custom\_error\_response) | One or more custom error response elements (list of maps) | `any` | `[]` | no |
| <a name="input_default_root_object"></a> [default\_root\_object](#input\_default\_root\_object) | Object that you want CloudFront to return when a user requests the root URL | `string` | `"index.html"` | no |
| <a name="input_enabled"></a> [enabled](#input\_enabled) | Whether the distribution is enabled to accept end user requests | `bool` | `true` | no |
| <a name="input_geo_restriction"></a> [geo\_restriction](#input\_geo\_restriction) | Geographic restriction configuration (map with restriction\_type and locations) | `any` | <pre>{<br/>  "locations": [],<br/>  "restriction_type": "none"<br/>}</pre> | no |
| <a name="input_is_ipv6_enabled"></a> [is\_ipv6\_enabled](#input\_is\_ipv6\_enabled) | Whether IPv6 is enabled for the distribution | `bool` | `true` | no |
| <a name="input_logging_config"></a> [logging\_config](#input\_logging\_config) | Logging configuration for the distribution (map with bucket, include\_cookies, prefix) | `any` | `{}` | no |
| <a name="input_ordered_cache_behavior"></a> [ordered\_cache\_behavior](#input\_ordered\_cache\_behavior) | Ordered list of cache behaviors resource for this distribution (list of maps) | `any` | `[]` | no |
| <a name="input_origin_group"></a> [origin\_group](#input\_origin\_group) | One or more origin groups for this distribution (map) | `any` | `{}` | no |
| <a name="input_price_class"></a> [price\_class](#input\_price\_class) | Price class for the CloudFront distribution (PriceClass\_All, PriceClass\_200, PriceClass\_100) | `string` | `"PriceClass_100"` | no |
| <a name="input_retain_on_delete"></a> [retain\_on\_delete](#input\_retain\_on\_delete) | Disables the distribution instead of deleting it when destroying the resource | `bool` | `false` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Additional tags to merge with common tags | `map(string)` | `{}` | no |
| <a name="input_viewer_certificate"></a> [viewer\_certificate](#input\_viewer\_certificate) | The SSL configuration for this distribution (map) | `any` | <pre>{<br/>  "cloudfront_default_certificate": true<br/>}</pre> | no |
| <a name="input_wait_for_deployment"></a> [wait\_for\_deployment](#input\_wait\_for\_deployment) | Wait for the distribution status to change from InProgress to Deployed | `bool` | `true` | no |
| <a name="input_web_acl_id"></a> [web\_acl\_id](#input\_web\_acl\_id) | ARN of the AWS WAF web ACL to associate with the distribution | `string` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_cloudfront_distribution_arn"></a> [cloudfront\_distribution\_arn](#output\_cloudfront\_distribution\_arn) | The ARN (Amazon Resource Name) for the CloudFront distribution |
| <a name="output_cloudfront_distribution_caller_reference"></a> [cloudfront\_distribution\_caller\_reference](#output\_cloudfront\_distribution\_caller\_reference) | Internal value used by CloudFront to allow future updates to the distribution configuration |
| <a name="output_cloudfront_distribution_domain_name"></a> [cloudfront\_distribution\_domain\_name](#output\_cloudfront\_distribution\_domain\_name) | The domain name corresponding to the CloudFront distribution |
| <a name="output_cloudfront_distribution_etag"></a> [cloudfront\_distribution\_etag](#output\_cloudfront\_distribution\_etag) | The current version of the distribution's information |
| <a name="output_cloudfront_distribution_hosted_zone_id"></a> [cloudfront\_distribution\_hosted\_zone\_id](#output\_cloudfront\_distribution\_hosted\_zone\_id) | The CloudFront Route 53 zone ID for alias records |
| <a name="output_cloudfront_distribution_id"></a> [cloudfront\_distribution\_id](#output\_cloudfront\_distribution\_id) | The identifier for the CloudFront distribution |
| <a name="output_cloudfront_distribution_status"></a> [cloudfront\_distribution\_status](#output\_cloudfront\_distribution\_status) | The current status of the distribution (Deployed or InProgress) |
| <a name="output_cloudfront_monitoring_subscription_id"></a> [cloudfront\_monitoring\_subscription\_id](#output\_cloudfront\_monitoring\_subscription\_id) | The ID of the CloudFront monitoring subscription |
| <a name="output_cloudfront_origin_access_controls"></a> [cloudfront\_origin\_access\_controls](#output\_cloudfront\_origin\_access\_controls) | The origin access controls created for the distribution |
| <a name="output_cloudfront_origin_access_identity_iam_arns"></a> [cloudfront\_origin\_access\_identity\_iam\_arns](#output\_cloudfront\_origin\_access\_identity\_iam\_arns) | The IAM ARNs of the CloudFront origin access identities |
| <a name="output_cloudfront_origin_access_identity_ids"></a> [cloudfront\_origin\_access\_identity\_ids](#output\_cloudfront\_origin\_access\_identity\_ids) | The IDs of the CloudFront origin access identities |
<!-- END_TF_DOCS -->