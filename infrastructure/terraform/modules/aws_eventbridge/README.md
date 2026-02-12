<!-- BEGIN_TF_DOCS -->
# AWS EventBridge Module

Thin wrapper around [terraform-aws-modules/eventbridge/aws](https://registry.terraform.io/modules/terraform-aws-modules/eventbridge/aws/latest).

This module provides organization-wide standards for AWS EventBridge:
- Custom event buses with logging configuration
- Event rules with pattern matching
- Event targets (Lambda, SQS, SNS, Step Functions, ECS, Kinesis, etc.)
- IAM roles with service-specific policies
- Event archives and replays
- Event permissions for cross-account access
- API destinations and connections
- EventBridge Scheduler
- Standard naming and tagging conventions

## Requirements

No requirements.

## Providers

No providers.

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_eventbridge"></a> [eventbridge](#module\_eventbridge) | terraform-aws-modules/eventbridge/aws | ~> 4.3 |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_api_destinations"></a> [api\_destinations](#input\_api\_destinations) | Map of EventBridge Destination definitions | `any` | `{}` | no |
| <a name="input_append_connection_postfix"></a> [append\_connection\_postfix](#input\_append\_connection\_postfix) | Controls whether to append '-connection' to the name of the connection | `bool` | `true` | no |
| <a name="input_append_destination_postfix"></a> [append\_destination\_postfix](#input\_append\_destination\_postfix) | Controls whether to append '-destination' to the name of the destination | `bool` | `true` | no |
| <a name="input_append_pipe_postfix"></a> [append\_pipe\_postfix](#input\_append\_pipe\_postfix) | Controls whether to append '-pipe' to the name of the pipe | `bool` | `true` | no |
| <a name="input_append_rule_postfix"></a> [append\_rule\_postfix](#input\_append\_rule\_postfix) | Controls whether to append '-rule' to the name of the rule | `bool` | `true` | no |
| <a name="input_append_schedule_group_postfix"></a> [append\_schedule\_group\_postfix](#input\_append\_schedule\_group\_postfix) | Controls whether to append '-group' to the name of the schedule group | `bool` | `true` | no |
| <a name="input_append_schedule_postfix"></a> [append\_schedule\_postfix](#input\_append\_schedule\_postfix) | Controls whether to append '-schedule' to the name of the schedule | `bool` | `true` | no |
| <a name="input_archives"></a> [archives](#input\_archives) | Map of EventBridge Archive definitions | `any` | `{}` | no |
| <a name="input_attach_api_destination_policy"></a> [attach\_api\_destination\_policy](#input\_attach\_api\_destination\_policy) | Controls whether the API Destination policy should be added to IAM role | `bool` | `false` | no |
| <a name="input_attach_cloudwatch_policy"></a> [attach\_cloudwatch\_policy](#input\_attach\_cloudwatch\_policy) | Controls whether the CloudWatch policy should be added to IAM role | `bool` | `false` | no |
| <a name="input_attach_ecs_policy"></a> [attach\_ecs\_policy](#input\_attach\_ecs\_policy) | Controls whether the ECS policy should be added to IAM role | `bool` | `false` | no |
| <a name="input_attach_kinesis_firehose_policy"></a> [attach\_kinesis\_firehose\_policy](#input\_attach\_kinesis\_firehose\_policy) | Controls whether the Kinesis Firehose policy should be added to IAM role | `bool` | `false` | no |
| <a name="input_attach_kinesis_policy"></a> [attach\_kinesis\_policy](#input\_attach\_kinesis\_policy) | Controls whether the Kinesis policy should be added to IAM role | `bool` | `false` | no |
| <a name="input_attach_lambda_policy"></a> [attach\_lambda\_policy](#input\_attach\_lambda\_policy) | Controls whether the Lambda Function policy should be added to IAM role | `bool` | `false` | no |
| <a name="input_attach_policies"></a> [attach\_policies](#input\_attach\_policies) | Controls whether list of policies should be added to IAM role | `bool` | `false` | no |
| <a name="input_attach_policy"></a> [attach\_policy](#input\_attach\_policy) | Controls whether policy should be added to IAM role | `bool` | `false` | no |
| <a name="input_attach_policy_json"></a> [attach\_policy\_json](#input\_attach\_policy\_json) | Controls whether policy\_json should be added to IAM role | `bool` | `false` | no |
| <a name="input_attach_policy_jsons"></a> [attach\_policy\_jsons](#input\_attach\_policy\_jsons) | Controls whether policy\_jsons should be added to IAM role | `bool` | `false` | no |
| <a name="input_attach_policy_statements"></a> [attach\_policy\_statements](#input\_attach\_policy\_statements) | Controls whether policy\_statements should be added to IAM role | `bool` | `false` | no |
| <a name="input_attach_sfn_policy"></a> [attach\_sfn\_policy](#input\_attach\_sfn\_policy) | Controls whether the Step Functions policy should be added to IAM role | `bool` | `false` | no |
| <a name="input_attach_sns_policy"></a> [attach\_sns\_policy](#input\_attach\_sns\_policy) | Controls whether the SNS policy should be added to IAM role | `bool` | `false` | no |
| <a name="input_attach_sqs_policy"></a> [attach\_sqs\_policy](#input\_attach\_sqs\_policy) | Controls whether the SQS policy should be added to IAM role | `bool` | `false` | no |
| <a name="input_attach_tracing_policy"></a> [attach\_tracing\_policy](#input\_attach\_tracing\_policy) | Controls whether X-Ray tracing policy should be added to IAM role | `bool` | `false` | no |
| <a name="input_bus_description"></a> [bus\_description](#input\_bus\_description) | Event bus description | `string` | `null` | no |
| <a name="input_bus_name"></a> [bus\_name](#input\_bus\_name) | Name identifier for the EventBridge Bus (will be prefixed with project-environment). Use null for default bus | `string` | `null` | no |
| <a name="input_cloudwatch_target_arns"></a> [cloudwatch\_target\_arns](#input\_cloudwatch\_target\_arns) | The ARNs of the CloudWatch Log Streams to use as EventBridge targets | `list(string)` | `[]` | no |
| <a name="input_connections"></a> [connections](#input\_connections) | Map of EventBridge Connection definitions | `any` | `{}` | no |
| <a name="input_context"></a> [context](#input\_context) | Context object containing project, environment, region, and common tags | <pre>object({<br/>    project     = string<br/>    environment = string<br/>    region      = string<br/>    common_tags = map(string)<br/>  })</pre> | n/a | yes |
| <a name="input_create"></a> [create](#input\_create) | Controls whether resources should be created | `bool` | `true` | no |
| <a name="input_create_api_destinations"></a> [create\_api\_destinations](#input\_create\_api\_destinations) | Controls whether EventBridge Destination resources should be created | `bool` | `false` | no |
| <a name="input_create_archives"></a> [create\_archives](#input\_create\_archives) | Controls whether EventBridge Archive resources should be created | `bool` | `false` | no |
| <a name="input_create_bus"></a> [create\_bus](#input\_create\_bus) | Controls whether EventBridge Bus resource should be created | `bool` | `true` | no |
| <a name="input_create_connections"></a> [create\_connections](#input\_create\_connections) | Controls whether EventBridge Connection resources should be created | `bool` | `false` | no |
| <a name="input_create_permissions"></a> [create\_permissions](#input\_create\_permissions) | Controls whether EventBridge Permission resources should be created | `bool` | `true` | no |
| <a name="input_create_pipes"></a> [create\_pipes](#input\_create\_pipes) | Controls whether EventBridge Pipes resources should be created | `bool` | `true` | no |
| <a name="input_create_role"></a> [create\_role](#input\_create\_role) | Controls whether IAM roles should be created | `bool` | `true` | no |
| <a name="input_create_rules"></a> [create\_rules](#input\_create\_rules) | Controls whether EventBridge Rule resources should be created | `bool` | `true` | no |
| <a name="input_create_schedule_groups"></a> [create\_schedule\_groups](#input\_create\_schedule\_groups) | Controls whether EventBridge Schedule Group resources should be created | `bool` | `true` | no |
| <a name="input_create_schedules"></a> [create\_schedules](#input\_create\_schedules) | Controls whether EventBridge Schedule resources should be created | `bool` | `true` | no |
| <a name="input_create_schemas_discoverer"></a> [create\_schemas\_discoverer](#input\_create\_schemas\_discoverer) | Controls whether default schemas discoverer should be created | `bool` | `false` | no |
| <a name="input_create_targets"></a> [create\_targets](#input\_create\_targets) | Controls whether EventBridge Target resources should be created | `bool` | `true` | no |
| <a name="input_ecs_pass_role_resources"></a> [ecs\_pass\_role\_resources](#input\_ecs\_pass\_role\_resources) | List of approved roles to be passed for ECS tasks | `list(string)` | `[]` | no |
| <a name="input_ecs_target_arns"></a> [ecs\_target\_arns](#input\_ecs\_target\_arns) | The ARNs of the AWS ECS Tasks to use as EventBridge targets | `list(string)` | `[]` | no |
| <a name="input_event_source_name"></a> [event\_source\_name](#input\_event\_source\_name) | The partner event source that the new event bus will be matched with | `string` | `null` | no |
| <a name="input_kinesis_firehose_target_arns"></a> [kinesis\_firehose\_target\_arns](#input\_kinesis\_firehose\_target\_arns) | The ARNs of the Kinesis Firehose Delivery Streams to use as EventBridge targets | `list(string)` | `[]` | no |
| <a name="input_kinesis_target_arns"></a> [kinesis\_target\_arns](#input\_kinesis\_target\_arns) | The ARNs of the Kinesis Streams to use as EventBridge targets | `list(string)` | `[]` | no |
| <a name="input_kms_key_identifier"></a> [kms\_key\_identifier](#input\_kms\_key\_identifier) | The identifier of the AWS KMS customer managed key for EventBridge to use | `string` | `null` | no |
| <a name="input_lambda_target_arns"></a> [lambda\_target\_arns](#input\_lambda\_target\_arns) | The ARNs of the Lambda Functions to use as EventBridge targets | `list(string)` | `[]` | no |
| <a name="input_log_config"></a> [log\_config](#input\_log\_config) | The configuration block for the EventBridge bus log config settings | <pre>object({<br/>    include_detail = string<br/>    level          = string<br/>  })</pre> | `null` | no |
| <a name="input_log_delivery"></a> [log\_delivery](#input\_log\_delivery) | Map of the configuration block for the EventBridge bus log delivery settings | `any` | `{}` | no |
| <a name="input_number_of_policies"></a> [number\_of\_policies](#input\_number\_of\_policies) | Number of policies to attach to IAM role | `number` | `0` | no |
| <a name="input_number_of_policy_jsons"></a> [number\_of\_policy\_jsons](#input\_number\_of\_policy\_jsons) | Number of policies JSON to attach to IAM role | `number` | `0` | no |
| <a name="input_permissions"></a> [permissions](#input\_permissions) | Map of EventBridge Permission definitions | `any` | `{}` | no |
| <a name="input_pipes"></a> [pipes](#input\_pipes) | Map of EventBridge Pipe definitions | `any` | `{}` | no |
| <a name="input_policies"></a> [policies](#input\_policies) | List of policy statements ARN to attach to IAM role | `list(string)` | `[]` | no |
| <a name="input_policy"></a> [policy](#input\_policy) | An additional policy document ARN to attach to IAM role | `string` | `null` | no |
| <a name="input_policy_json"></a> [policy\_json](#input\_policy\_json) | An additional policy document as JSON to attach to IAM role | `string` | `null` | no |
| <a name="input_policy_jsons"></a> [policy\_jsons](#input\_policy\_jsons) | List of additional policy documents as JSON to attach to IAM role | `list(string)` | `[]` | no |
| <a name="input_policy_statements"></a> [policy\_statements](#input\_policy\_statements) | Map of dynamic policy statements to attach to IAM role | `any` | `{}` | no |
| <a name="input_rules"></a> [rules](#input\_rules) | Map of EventBridge Rule definitions | `any` | `{}` | no |
| <a name="input_schedule_groups"></a> [schedule\_groups](#input\_schedule\_groups) | Map of EventBridge Schedule Group definitions | `any` | `{}` | no |
| <a name="input_schedules"></a> [schedules](#input\_schedules) | Map of EventBridge Schedule definitions | `any` | `{}` | no |
| <a name="input_sfn_target_arns"></a> [sfn\_target\_arns](#input\_sfn\_target\_arns) | The ARNs of the Step Functions state machines to use as EventBridge targets | `list(string)` | `[]` | no |
| <a name="input_sns_target_arns"></a> [sns\_target\_arns](#input\_sns\_target\_arns) | The ARNs of the SNS topics to use as EventBridge targets | `list(string)` | `[]` | no |
| <a name="input_sqs_target_arns"></a> [sqs\_target\_arns](#input\_sqs\_target\_arns) | The ARNs of the SQS queues to use as EventBridge targets | `list(string)` | `[]` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Additional tags to merge with common tags | `map(string)` | `{}` | no |
| <a name="input_targets"></a> [targets](#input\_targets) | Map of EventBridge Target definitions | `any` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_eventbridge_api_destinations"></a> [eventbridge\_api\_destinations](#output\_eventbridge\_api\_destinations) | Map of EventBridge API destinations created and their attributes |
| <a name="output_eventbridge_archives"></a> [eventbridge\_archives](#output\_eventbridge\_archives) | Map of EventBridge archives created and their attributes |
| <a name="output_eventbridge_bus_arn"></a> [eventbridge\_bus\_arn](#output\_eventbridge\_bus\_arn) | The ARN of the EventBridge bus |
| <a name="output_eventbridge_bus_name"></a> [eventbridge\_bus\_name](#output\_eventbridge\_bus\_name) | The name of the EventBridge bus |
| <a name="output_eventbridge_connections"></a> [eventbridge\_connections](#output\_eventbridge\_connections) | Map of EventBridge connections created and their attributes |
| <a name="output_eventbridge_permissions"></a> [eventbridge\_permissions](#output\_eventbridge\_permissions) | Map of EventBridge permissions created and their attributes |
| <a name="output_eventbridge_pipe_role_arn"></a> [eventbridge\_pipe\_role\_arn](#output\_eventbridge\_pipe\_role\_arn) | The ARN of the IAM role created for EventBridge Pipes |
| <a name="output_eventbridge_pipe_role_name"></a> [eventbridge\_pipe\_role\_name](#output\_eventbridge\_pipe\_role\_name) | The name of the IAM role created for EventBridge Pipes |
| <a name="output_eventbridge_pipes"></a> [eventbridge\_pipes](#output\_eventbridge\_pipes) | Map of EventBridge pipes created and their attributes |
| <a name="output_eventbridge_role_arn"></a> [eventbridge\_role\_arn](#output\_eventbridge\_role\_arn) | The ARN of the IAM role created for EventBridge |
| <a name="output_eventbridge_role_name"></a> [eventbridge\_role\_name](#output\_eventbridge\_role\_name) | The name of the IAM role created for EventBridge |
| <a name="output_eventbridge_rules"></a> [eventbridge\_rules](#output\_eventbridge\_rules) | Map of EventBridge rules created and their attributes |
| <a name="output_eventbridge_schedule_groups"></a> [eventbridge\_schedule\_groups](#output\_eventbridge\_schedule\_groups) | Map of EventBridge schedule groups created and their attributes |
| <a name="output_eventbridge_schedules"></a> [eventbridge\_schedules](#output\_eventbridge\_schedules) | Map of EventBridge schedules created and their attributes |
| <a name="output_eventbridge_targets"></a> [eventbridge\_targets](#output\_eventbridge\_targets) | Map of EventBridge targets created and their attributes |
<!-- END_TF_DOCS -->