<!-- BEGIN_TF_DOCS -->
## Requirements

No requirements.

## Providers

No providers.

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_lambda_function"></a> [lambda\_function](#module\_lambda\_function) | terraform-aws-modules/lambda/aws | ~> 7.0 |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_context"></a> [context](#input\_context) | Context object containing project, environment, region, and common tags | <pre>object({<br/>    project     = string<br/>    environment = string<br/>    region      = string<br/>    common_tags = map(string)<br/>  })</pre> | n/a | yes |
| <a name="input_function_name"></a> [function\_name](#input\_function\_name) | Unique name for this Lambda function (will be prefixed with project-environment) | `string` | n/a | yes |
| <a name="input_lambda_role"></a> [lambda\_role](#input\_lambda\_role) | IAM role ARN for Lambda execution | `string` | n/a | yes |
| <a name="input_attach_policy_statements"></a> [attach\_policy\_statements](#input\_attach\_policy\_statements) | Whether to attach additional IAM policy statements | `bool` | `false` | no |
| <a name="input_cloudwatch_logs_retention_in_days"></a> [cloudwatch\_logs\_retention\_in\_days](#input\_cloudwatch\_logs\_retention\_in\_days) | CloudWatch Logs retention in days (defaults to environment-based: prod=30, others=7) | `number` | `null` | no |
| <a name="input_create_package"></a> [create\_package](#input\_create\_package) | Whether to create a deployment package | `bool` | `false` | no |
| <a name="input_description"></a> [description](#input\_description) | Description of the Lambda function | `string` | `""` | no |
| <a name="input_environment_variables"></a> [environment\_variables](#input\_environment\_variables) | Map of environment variables for the Lambda function | `map(string)` | `{}` | no |
| <a name="input_handler"></a> [handler](#input\_handler) | Lambda function handler (for Zip packages) | `string` | `"index.handler"` | no |
| <a name="input_image_uri"></a> [image\_uri](#input\_image\_uri) | ECR image URI for container-based Lambda (recommended for complex dependencies) | `string` | `null` | no |
| <a name="input_local_existing_package"></a> [local\_existing\_package](#input\_local\_existing\_package) | Path to an existing local deployment package | `string` | `null` | no |
| <a name="input_memory_size"></a> [memory\_size](#input\_memory\_size) | Amount of memory in MB available to the function | `number` | `1024` | no |
| <a name="input_package_type"></a> [package\_type](#input\_package\_type) | Lambda deployment package type: Zip or Image | `string` | `"Zip"` | no |
| <a name="input_policy_statements"></a> [policy\_statements](#input\_policy\_statements) | Map of IAM policy statements to attach to the Lambda role | `any` | `{}` | no |
| <a name="input_runtime"></a> [runtime](#input\_runtime) | Lambda runtime (e.g., python3.11, nodejs20.x) | `string` | `"python3.11"` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Additional tags for the Lambda function | `map(string)` | `{}` | no |
| <a name="input_timeout"></a> [timeout](#input\_timeout) | Function timeout in seconds | `number` | `300` | no |
| <a name="input_vpc_security_group_ids"></a> [vpc\_security\_group\_ids](#input\_vpc\_security\_group\_ids) | List of security group IDs for VPC configuration | `list(string)` | `[]` | no |
| <a name="input_vpc_subnet_ids"></a> [vpc\_subnet\_ids](#input\_vpc\_subnet\_ids) | List of subnet IDs for VPC configuration | `list(string)` | `[]` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_lambda_cloudwatch_log_group_arn"></a> [lambda\_cloudwatch\_log\_group\_arn](#output\_lambda\_cloudwatch\_log\_group\_arn) | ARN of the CloudWatch Log Group for the Lambda function |
| <a name="output_lambda_cloudwatch_log_group_name"></a> [lambda\_cloudwatch\_log\_group\_name](#output\_lambda\_cloudwatch\_log\_group\_name) | Name of the CloudWatch Log Group for the Lambda function |
| <a name="output_lambda_function_arn"></a> [lambda\_function\_arn](#output\_lambda\_function\_arn) | ARN of the Lambda function |
| <a name="output_lambda_function_invoke_arn"></a> [lambda\_function\_invoke\_arn](#output\_lambda\_function\_invoke\_arn) | Invoke ARN of the Lambda function for API Gateway integration |
| <a name="output_lambda_function_name"></a> [lambda\_function\_name](#output\_lambda\_function\_name) | Name of the Lambda function |
| <a name="output_lambda_function_qualified_arn"></a> [lambda\_function\_qualified\_arn](#output\_lambda\_function\_qualified\_arn) | Qualified ARN of the Lambda function (includes version) |
| <a name="output_lambda_role_arn"></a> [lambda\_role\_arn](#output\_lambda\_role\_arn) | ARN of the IAM role used by the Lambda function |
<!-- END_TF_DOCS -->