<!-- BEGIN_TF_DOCS -->
# EventBridge Module

Thin wrapper around [terraform-aws-modules/eventbridge/aws](https://registry.terraform.io/modules/terraform-aws-modules/eventbridge/aws/latest).

This module provides organization-wide standards for EventBridge:
- Naming convention: `{project}-{environment}-{bus_name}` for custom event buses
- Standard tagging with project, environment, and component
- Support for both default and custom event buses
- Flexible rule and target configuration

**Note**: Specific event rules and targets should be defined in the root module
to maintain flexibility and separation of business logic.

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

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | n/a |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_eventbridge"></a> [eventbridge](#module\_eventbridge) | terraform-aws-modules/eventbridge/aws | ~> 3.0 |

## Resources

| Name | Type |
|------|------|
| [aws_cloudwatch_event_bus.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_bus) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_context"></a> [context](#input\_context) | Context object containing project, environment, region, and common tags | <pre>object({<br/>    project     = string<br/>    environment = string<br/>    region      = string<br/>    common_tags = map(string)<br/>  })</pre> | n/a | yes |
| <a name="input_bus_name"></a> [bus\_name](#input\_bus\_name) | Name of the EventBridge event bus (will be prefixed if creating custom bus) | `string` | `"default"` | no |
| <a name="input_create_bus"></a> [create\_bus](#input\_create\_bus) | Whether to create a custom EventBridge event bus | `bool` | `false` | no |
| <a name="input_rules"></a> [rules](#input\_rules) | Map of EventBridge rules configuration (mirrors terraform-aws-modules/eventbridge) | `any` | `{}` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Additional tags for EventBridge resources | `map(string)` | `{}` | no |
| <a name="input_targets"></a> [targets](#input\_targets) | Map of EventBridge targets configuration (mirrors terraform-aws-modules/eventbridge) | `any` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_eventbridge_bus_arn"></a> [eventbridge\_bus\_arn](#output\_eventbridge\_bus\_arn) | ARN of the EventBridge event bus |
| <a name="output_eventbridge_bus_name"></a> [eventbridge\_bus\_name](#output\_eventbridge\_bus\_name) | Name of the EventBridge event bus |
| <a name="output_eventbridge_rule_arns"></a> [eventbridge\_rule\_arns](#output\_eventbridge\_rule\_arns) | Map of EventBridge rule ARNs |
| <a name="output_eventbridge_rule_ids"></a> [eventbridge\_rule\_ids](#output\_eventbridge\_rule\_ids) | Map of EventBridge rule IDs |
<!-- END_TF_DOCS -->