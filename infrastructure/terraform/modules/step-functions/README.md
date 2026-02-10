<!-- BEGIN_TF_DOCS -->
# Step Functions State Machine Module

Thin wrapper around [terraform-aws-modules/step-functions/aws](https://registry.terraform.io/modules/terraform-aws-modules/step-functions/aws/latest).

This module provides organization-wide standards for Step Functions:
- Naming convention: `{project}-{environment}-{state_machine_name}`
- Standard tagging with project, environment, and component
- Environment-based log retention (prod=30 days, others=7 days)
- CloudWatch Logs integration with structured logging
- Configurable execution data inclusion for non-production environments

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
| <a name="module_step_function"></a> [step\_function](#module\_step\_function) | terraform-aws-modules/step-functions/aws | ~> 4.0 |

## Resources

| Name | Type |
|------|------|
| [aws_cloudwatch_log_group.step_functions](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_context"></a> [context](#input\_context) | Context object containing project, environment, region, and common tags | <pre>object({<br/>    project     = string<br/>    environment = string<br/>    region      = string<br/>    common_tags = map(string)<br/>  })</pre> | n/a | yes |
| <a name="input_definition"></a> [definition](#input\_definition) | Amazon States Language definition of the state machine (JSON string) | `string` | n/a | yes |
| <a name="input_role_arn"></a> [role\_arn](#input\_role\_arn) | IAM role ARN for Step Functions execution | `string` | n/a | yes |
| <a name="input_state_machine_name"></a> [state\_machine\_name](#input\_state\_machine\_name) | Name of the Step Functions state machine (will be prefixed with project-environment) | `string` | n/a | yes |
| <a name="input_cloudwatch_logs_retention_in_days"></a> [cloudwatch\_logs\_retention\_in\_days](#input\_cloudwatch\_logs\_retention\_in\_days) | CloudWatch Logs retention in days (defaults to environment-based: prod=30, others=7) | `number` | `null` | no |
| <a name="input_include_execution_data"></a> [include\_execution\_data](#input\_include\_execution\_data) | Include execution data in CloudWatch Logs (recommended for non-production only) | `bool` | `false` | no |
| <a name="input_log_level"></a> [log\_level](#input\_log\_level) | CloudWatch Logs log level: ALL, ERROR, FATAL, or OFF | `string` | `"ALL"` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Additional tags for the Step Functions state machine | `map(string)` | `{}` | no |
| <a name="input_type"></a> [type](#input\_type) | Type of Step Functions state machine: STANDARD or EXPRESS | `string` | `"STANDARD"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_cloudwatch_log_group_arn"></a> [cloudwatch\_log\_group\_arn](#output\_cloudwatch\_log\_group\_arn) | ARN of the CloudWatch Log Group for Step Functions execution logs |
| <a name="output_cloudwatch_log_group_name"></a> [cloudwatch\_log\_group\_name](#output\_cloudwatch\_log\_group\_name) | Name of the CloudWatch Log Group for Step Functions execution logs |
| <a name="output_role_arn"></a> [role\_arn](#output\_role\_arn) | ARN of the IAM role used by the Step Functions state machine |
| <a name="output_state_machine_arn"></a> [state\_machine\_arn](#output\_state\_machine\_arn) | ARN of the Step Functions state machine |
| <a name="output_state_machine_creation_date"></a> [state\_machine\_creation\_date](#output\_state\_machine\_creation\_date) | Creation date of the Step Functions state machine |
| <a name="output_state_machine_id"></a> [state\_machine\_id](#output\_state\_machine\_id) | ID of the Step Functions state machine |
| <a name="output_state_machine_name"></a> [state\_machine\_name](#output\_state\_machine\_name) | Name of the Step Functions state machine |
| <a name="output_state_machine_status"></a> [state\_machine\_status](#output\_state\_machine\_status) | Current status of the Step Functions state machine |
<!-- END_TF_DOCS -->