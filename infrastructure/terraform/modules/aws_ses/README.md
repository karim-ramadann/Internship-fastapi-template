<!-- BEGIN_TF_DOCS -->
# SES Module

Thin wrapper around [terraform-aws-modules/ses/aws](https://registry.terraform.io/modules/terraform-aws-modules/ses/aws/latest).

Standards enforced:
- Naming convention for configuration set: `{project}-{environment}`
- Domain identity verification via Route53
- DKIM signing enabled by default
- MAIL FROM domain configuration
- Standard tagging

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
| <a name="module_ses"></a> [ses](#module\_ses) | terraform-aws-modules/ses/aws | ~> 1.0 |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_context"></a> [context](#input\_context) | Context object containing project, environment, region, and common tags | <pre>object({<br/>    project     = string<br/>    environment = string<br/>    region      = string<br/>    common_tags = map(string)<br/>  })</pre> | n/a | yes |
| <a name="input_domain"></a> [domain](#input\_domain) | Domain name for SES identity | `string` | n/a | yes |
| <a name="input_create_configuration_set"></a> [create\_configuration\_set](#input\_create\_configuration\_set) | Whether to create an SES configuration set | `bool` | `true` | no |
| <a name="input_email_identities"></a> [email\_identities](#input\_email\_identities) | Map of email identities to create | `any` | `{}` | no |
| <a name="input_mail_from_subdomain"></a> [mail\_from\_subdomain](#input\_mail\_from\_subdomain) | Subdomain for MAIL FROM (e.g., 'mail' creates mail.domain.com) | `string` | `"mail"` | no |
| <a name="input_route53_zone_id"></a> [route53\_zone\_id](#input\_route53\_zone\_id) | Route53 hosted zone ID for DNS verification | `string` | `""` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Additional tags to merge with common tags | `map(string)` | `{}` | no |
| <a name="input_templates"></a> [templates](#input\_templates) | Map of SES email templates | `any` | `{}` | no |
| <a name="input_verify_dkim"></a> [verify\_dkim](#input\_verify\_dkim) | Whether to verify DKIM for the domain | `bool` | `true` | no |
| <a name="input_verify_domain"></a> [verify\_domain](#input\_verify\_domain) | Whether to verify the domain identity via DNS | `bool` | `true` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_ses_configuration_set_name"></a> [ses\_configuration\_set\_name](#output\_ses\_configuration\_set\_name) | Name of the SES configuration set |
| <a name="output_ses_domain_identity_arn"></a> [ses\_domain\_identity\_arn](#output\_ses\_domain\_identity\_arn) | ARN of the SES domain identity |
| <a name="output_ses_domain_identity_verification_token"></a> [ses\_domain\_identity\_verification\_token](#output\_ses\_domain\_identity\_verification\_token) | Verification token for the domain identity |
<!-- END_TF_DOCS -->
