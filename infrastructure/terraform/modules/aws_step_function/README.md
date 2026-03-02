<!-- BEGIN_TF_DOCS -->
# AWS Step Functions Module

Thin wrapper around [terraform-aws-modules/step-functions/aws](https://registry.terraform.io/modules/terraform-aws-modules/step-functions/aws/latest).

This module provides organization-wide standards for AWS Step Functions:
- Standard naming and tagging conventions
- IAM role with service integrations (Lambda, SQS, ECS, Batch, DynamoDB, etc.)
- CloudWatch Logs integration for execution history
- Support for STANDARD and EXPRESS state machine types
- Encryption configuration for data at rest

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
| <a name="module_step_function"></a> [step\_function](#module\_step\_function) | terraform-aws-modules/step-functions/aws | ~> 5.0 |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_context"></a> [context](#input\_context) | Context object containing project, environment, region, and common tags | <pre>object({<br/>    project     = string<br/>    environment = string<br/>    region      = string<br/>    common_tags = map(string)<br/>  })</pre> | n/a | yes |
| <a name="input_definition"></a> [definition](#input\_definition) | The Amazon States Language definition of the Step Function | `string` | n/a | yes |
| <a name="input_name"></a> [name](#input\_name) | Name identifier for the Step Function (will be prefixed with project-environment) | `string` | n/a | yes |
| <a name="input_attach_cloudwatch_logs_policy"></a> [attach\_cloudwatch\_logs\_policy](#input\_attach\_cloudwatch\_logs\_policy) | Controls whether CloudWatch Logs policy should be added to IAM role | `bool` | `true` | no |
| <a name="input_attach_policies"></a> [attach\_policies](#input\_attach\_policies) | Controls whether list of policies should be added to IAM role | `bool` | `false` | no |
| <a name="input_attach_policies_for_integrations"></a> [attach\_policies\_for\_integrations](#input\_attach\_policies\_for\_integrations) | Whether to attach AWS Service policies to IAM role | `bool` | `true` | no |
| <a name="input_attach_policy"></a> [attach\_policy](#input\_attach\_policy) | Controls whether policy should be added to IAM role | `bool` | `false` | no |
| <a name="input_attach_policy_json"></a> [attach\_policy\_json](#input\_attach\_policy\_json) | Controls whether policy\_json should be added to IAM role | `bool` | `false` | no |
| <a name="input_attach_policy_jsons"></a> [attach\_policy\_jsons](#input\_attach\_policy\_jsons) | Controls whether policy\_jsons should be added to IAM role | `bool` | `false` | no |
| <a name="input_attach_policy_statements"></a> [attach\_policy\_statements](#input\_attach\_policy\_statements) | Controls whether policy\_statements should be added to IAM role | `bool` | `false` | no |
| <a name="input_aws_region_assume_role"></a> [aws\_region\_assume\_role](#input\_aws\_region\_assume\_role) | Name of AWS regions where IAM role can be assumed by the Step Function | `string` | `""` | no |
| <a name="input_cloudwatch_log_group_kms_key_id"></a> [cloudwatch\_log\_group\_kms\_key\_id](#input\_cloudwatch\_log\_group\_kms\_key\_id) | The ARN of the KMS Key to use when encrypting log data | `string` | `null` | no |
| <a name="input_cloudwatch_log_group_name"></a> [cloudwatch\_log\_group\_name](#input\_cloudwatch\_log\_group\_name) | Name of CloudWatch Logs group name to use | `string` | `null` | no |
| <a name="input_cloudwatch_log_group_retention_in_days"></a> [cloudwatch\_log\_group\_retention\_in\_days](#input\_cloudwatch\_log\_group\_retention\_in\_days) | Specifies the number of days you want to retain log events in the specified log group | `number` | `null` | no |
| <a name="input_cloudwatch_log_group_tags"></a> [cloudwatch\_log\_group\_tags](#input\_cloudwatch\_log\_group\_tags) | Additional tags to assign to CloudWatch log group | `map(string)` | `{}` | no |
| <a name="input_create_role"></a> [create\_role](#input\_create\_role) | Whether to create IAM role for the Step Function | `bool` | `true` | no |
| <a name="input_encryption_configuration"></a> [encryption\_configuration](#input\_encryption\_configuration) | Defines what encryption configuration is used to encrypt data in the State Machine | `any` | `{}` | no |
| <a name="input_logging_configuration"></a> [logging\_configuration](#input\_logging\_configuration) | Defines what execution history events are logged and where they are logged | `map(string)` | `{}` | no |
| <a name="input_number_of_policies"></a> [number\_of\_policies](#input\_number\_of\_policies) | Number of policies to attach to IAM role | `number` | `0` | no |
| <a name="input_number_of_policy_jsons"></a> [number\_of\_policy\_jsons](#input\_number\_of\_policy\_jsons) | Number of policies JSON to attach to IAM role | `number` | `0` | no |
| <a name="input_policies"></a> [policies](#input\_policies) | List of policy statements ARN to attach to IAM role | `list(string)` | `[]` | no |
| <a name="input_policy"></a> [policy](#input\_policy) | An additional policy document ARN to attach to IAM role | `string` | `null` | no |
| <a name="input_policy_json"></a> [policy\_json](#input\_policy\_json) | An additional policy document as JSON to attach to IAM role | `string` | `null` | no |
| <a name="input_policy_jsons"></a> [policy\_jsons](#input\_policy\_jsons) | List of additional policy documents as JSON to attach to IAM role | `list(string)` | `[]` | no |
| <a name="input_policy_path"></a> [policy\_path](#input\_policy\_path) | Path of IAM policies to use for Step Function | `string` | `null` | no |
| <a name="input_policy_statements"></a> [policy\_statements](#input\_policy\_statements) | Map of dynamic policy statements to attach to IAM role | `any` | `{}` | no |
| <a name="input_publish"></a> [publish](#input\_publish) | Determines whether to set a version of the state machine when it is created | `bool` | `false` | no |
| <a name="input_role_arn"></a> [role\_arn](#input\_role\_arn) | The Amazon Resource Name (ARN) of the IAM role to use for this Step Function | `string` | `""` | no |
| <a name="input_role_description"></a> [role\_description](#input\_role\_description) | Description of IAM role to use for Step Function | `string` | `null` | no |
| <a name="input_role_force_detach_policies"></a> [role\_force\_detach\_policies](#input\_role\_force\_detach\_policies) | Specifies to force detaching any policies the IAM role has before destroying it | `bool` | `true` | no |
| <a name="input_role_name"></a> [role\_name](#input\_role\_name) | Name of IAM role to use for Step Function | `string` | `null` | no |
| <a name="input_role_path"></a> [role\_path](#input\_role\_path) | Path of IAM role to use for Step Function | `string` | `null` | no |
| <a name="input_role_permissions_boundary"></a> [role\_permissions\_boundary](#input\_role\_permissions\_boundary) | The ARN of the policy that is used to set the permissions boundary for the IAM role | `string` | `null` | no |
| <a name="input_role_tags"></a> [role\_tags](#input\_role\_tags) | Additional tags to assign to IAM role | `map(string)` | `{}` | no |
| <a name="input_service_integrations"></a> [service\_integrations](#input\_service\_integrations) | Map of AWS service integrations to allow in IAM role policy | `any` | `{}` | no |
| <a name="input_sfn_state_machine_timeouts"></a> [sfn\_state\_machine\_timeouts](#input\_sfn\_state\_machine\_timeouts) | Create, update, and delete timeout configurations for the step function | `map(string)` | `{}` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Additional tags to merge with common tags | `map(string)` | `{}` | no |
| <a name="input_trusted_entities"></a> [trusted\_entities](#input\_trusted\_entities) | Step Function additional trusted entities for assuming roles (trust relationship) | `list(string)` | `[]` | no |
| <a name="input_type"></a> [type](#input\_type) | Determines whether a Standard or Express state machine is created. Valid Values: STANDARD \| EXPRESS | `string` | `"STANDARD"` | no |
| <a name="input_use_existing_cloudwatch_log_group"></a> [use\_existing\_cloudwatch\_log\_group](#input\_use\_existing\_cloudwatch\_log\_group) | Whether to use an existing CloudWatch log group or create new | `bool` | `false` | no |
| <a name="input_use_existing_role"></a> [use\_existing\_role](#input\_use\_existing\_role) | Whether to use an existing IAM role for this Step Function | `bool` | `false` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_cloudwatch_log_group_arn"></a> [cloudwatch\_log\_group\_arn](#output\_cloudwatch\_log\_group\_arn) | The ARN of the CloudWatch log group created for the Step Function |
| <a name="output_cloudwatch_log_group_name"></a> [cloudwatch\_log\_group\_name](#output\_cloudwatch\_log\_group\_name) | The name of the CloudWatch log group created for the Step Function |
| <a name="output_role_arn"></a> [role\_arn](#output\_role\_arn) | The ARN of the IAM role created for the Step Function |
| <a name="output_role_name"></a> [role\_name](#output\_role\_name) | The name of the IAM role created for the Step Function |
| <a name="output_state_machine_arn"></a> [state\_machine\_arn](#output\_state\_machine\_arn) | The ARN of the Step Function |
| <a name="output_state_machine_creation_date"></a> [state\_machine\_creation\_date](#output\_state\_machine\_creation\_date) | The date the Step Function was created |
| <a name="output_state_machine_id"></a> [state\_machine\_id](#output\_state\_machine\_id) | The ARN of the Step Function |
| <a name="output_state_machine_name"></a> [state\_machine\_name](#output\_state\_machine\_name) | The name of the Step Function |
| <a name="output_state_machine_status"></a> [state\_machine\_status](#output\_state\_machine\_status) | The current status of the Step Function |
| <a name="output_state_machine_version_arn"></a> [state\_machine\_version\_arn](#output\_state\_machine\_version\_arn) | The ARN of state machine version |
<!-- END_TF_DOCS -->
