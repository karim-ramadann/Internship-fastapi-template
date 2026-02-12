<!-- BEGIN_TF_DOCS -->
# ACM Certificate Module

Thin wrapper around [terraform-aws-modules/acm/aws](https://registry.terraform.io/modules/terraform-aws-modules/acm/aws/latest).

This module provides organization-wide standards for SSL/TLS certificates:
- Automatic DNS validation via Route53
- Wildcard certificate support (*.domain.com)
- Standard tagging with project and environment
- Automatic validation waiting (no manual intervention)

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
| <a name="module_acm"></a> [acm](#module\_acm) | terraform-aws-modules/acm/aws | ~> 5.0 |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_context"></a> [context](#input\_context) | Context object containing project, environment, region, and common tags | <pre>object({<br/>    project     = string<br/>    environment = string<br/>    region      = string<br/>    common_tags = map(string)<br/>  })</pre> | n/a | yes |
| <a name="input_domain"></a> [domain](#input\_domain) | Primary domain name for the ACM certificate | `string` | n/a | yes |
| <a name="input_route53_zone_id"></a> [route53\_zone\_id](#input\_route53\_zone\_id) | Route53 hosted zone ID for DNS validation records | `string` | n/a | yes |
| <a name="input_subject_alternative_names"></a> [subject\_alternative\_names](#input\_subject\_alternative\_names) | Subject Alternative Names (SANs) for the certificate. Defaults to wildcard of primary domain | `list(string)` | `null` | no |
| <a name="input_validation_timeout"></a> [validation\_timeout](#input\_validation\_timeout) | Maximum time to wait for certificate validation | `string` | `"45m"` | no |
| <a name="input_wait_for_validation"></a> [wait\_for\_validation](#input\_wait\_for\_validation) | Wait for certificate validation to complete before returning | `bool` | `true` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_certificate_arn"></a> [certificate\_arn](#output\_certificate\_arn) | ARN of the validated ACM certificate |
| <a name="output_certificate_domain_name"></a> [certificate\_domain\_name](#output\_certificate\_domain\_name) | Primary domain name of the certificate |
| <a name="output_certificate_status"></a> [certificate\_status](#output\_certificate\_status) | Status of the ACM certificate |
| <a name="output_distinct_domain_names"></a> [distinct\_domain\_names](#output\_distinct\_domain\_names) | List of distinct domain names for certificate validation |
| <a name="output_validation_domains"></a> [validation\_domains](#output\_validation\_domains) | List of domains used for certificate validation |
| <a name="output_validation_route53_record_fqdns"></a> [validation\_route53\_record\_fqdns](#output\_validation\_route53\_record\_fqdns) | List of FQDNs built using the zone domain and name |
<!-- END_TF_DOCS -->