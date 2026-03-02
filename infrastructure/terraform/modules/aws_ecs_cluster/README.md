<!-- BEGIN_TF_DOCS -->
# AWS ECS Cluster Module

Thin wrapper around [terraform-aws-modules/ecs/aws](https://registry.terraform.io/modules/terraform-aws-modules/ecs/aws/latest).

This module provides organization-wide standards for ECS clusters:
- Fargate and/or EC2 capacity providers
- Container Insights enabled by default
- CloudWatch logging configuration
- Execute command configuration for debugging
- Service Connect defaults
- IAM roles for infrastructure and instances
- Standard naming and tagging conventions

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
| <a name="module_ecs_cluster"></a> [ecs\_cluster](#module\_ecs\_cluster) | terraform-aws-modules/ecs/aws | ~> 7.3 |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_context"></a> [context](#input\_context) | Context object containing project, environment, region, and common tags | <pre>object({<br/>    project     = string<br/>    environment = string<br/>    region      = string<br/>    common_tags = map(string)<br/>  })</pre> | n/a | yes |
| <a name="input_capacity_providers"></a> [capacity\_providers](#input\_capacity\_providers) | Map of capacity provider definitions to create for the cluster | `any` | `null` | no |
| <a name="input_cloudwatch_log_group_class"></a> [cloudwatch\_log\_group\_class](#input\_cloudwatch\_log\_group\_class) | Specified the log class of the log group. Possible values are: STANDARD or INFREQUENT\_ACCESS | `string` | `null` | no |
| <a name="input_cloudwatch_log_group_kms_key_id"></a> [cloudwatch\_log\_group\_kms\_key\_id](#input\_cloudwatch\_log\_group\_kms\_key\_id) | KMS Key ARN to use for encrypting the CloudWatch log group | `string` | `null` | no |
| <a name="input_cloudwatch_log_group_name"></a> [cloudwatch\_log\_group\_name](#input\_cloudwatch\_log\_group\_name) | Custom name of CloudWatch Log Group for ECS cluster | `string` | `null` | no |
| <a name="input_cloudwatch_log_group_retention_in_days"></a> [cloudwatch\_log\_group\_retention\_in\_days](#input\_cloudwatch\_log\_group\_retention\_in\_days) | Number of days to retain log events | `number` | `90` | no |
| <a name="input_cloudwatch_log_group_tags"></a> [cloudwatch\_log\_group\_tags](#input\_cloudwatch\_log\_group\_tags) | Additional tags to add to the CloudWatch log group | `map(string)` | `{}` | no |
| <a name="input_cluster_capacity_providers"></a> [cluster\_capacity\_providers](#input\_cluster\_capacity\_providers) | List of capacity provider names to associate with the ECS cluster (e.g., FARGATE, FARGATE\_SPOT) | `list(string)` | <pre>[<br/>  "FARGATE",<br/>  "FARGATE_SPOT"<br/>]</pre> | no |
| <a name="input_cluster_configuration"></a> [cluster\_configuration](#input\_cluster\_configuration) | The execute command configuration for the cluster | <pre>object({<br/>    execute_command_configuration = optional(object({<br/>      kms_key_id = optional(string)<br/>      log_configuration = optional(object({<br/>        cloud_watch_encryption_enabled = optional(bool)<br/>        cloud_watch_log_group_name     = optional(string)<br/>        s3_bucket_encryption_enabled   = optional(bool)<br/>        s3_bucket_name                 = optional(string)<br/>        s3_kms_key_id                  = optional(string)<br/>        s3_key_prefix                  = optional(string)<br/>      }))<br/>      logging = optional(string, "OVERRIDE")<br/>    }))<br/>    managed_storage_configuration = optional(object({<br/>      fargate_ephemeral_storage_kms_key_id = optional(string)<br/>      kms_key_id                           = optional(string)<br/>    }))<br/>  })</pre> | `null` | no |
| <a name="input_cluster_service_connect_defaults"></a> [cluster\_service\_connect\_defaults](#input\_cluster\_service\_connect\_defaults) | Configures a default Service Connect namespace | <pre>object({<br/>    namespace = string<br/>  })</pre> | `null` | no |
| <a name="input_cluster_setting"></a> [cluster\_setting](#input\_cluster\_setting) | List of configuration block(s) with cluster settings | <pre>list(object({<br/>    name  = string<br/>    value = string<br/>  }))</pre> | <pre>[<br/>  {<br/>    "name": "containerInsights",<br/>    "value": "enabled"<br/>  }<br/>]</pre> | no |
| <a name="input_cluster_tags"></a> [cluster\_tags](#input\_cluster\_tags) | Additional tags to add to the cluster resource | `map(string)` | `{}` | no |
| <a name="input_create_cloudwatch_log_group"></a> [create\_cloudwatch\_log\_group](#input\_create\_cloudwatch\_log\_group) | Determines whether a log group is created by this module for the cluster logs | `bool` | `true` | no |
| <a name="input_create_infrastructure_iam_role"></a> [create\_infrastructure\_iam\_role](#input\_create\_infrastructure\_iam\_role) | Determines whether the ECS infrastructure IAM role should be created | `bool` | `true` | no |
| <a name="input_create_node_iam_instance_profile"></a> [create\_node\_iam\_instance\_profile](#input\_create\_node\_iam\_instance\_profile) | Determines whether an IAM instance profile is created or to use an existing IAM instance profile | `bool` | `true` | no |
| <a name="input_create_task_exec_iam_role"></a> [create\_task\_exec\_iam\_role](#input\_create\_task\_exec\_iam\_role) | Determines whether the ECS task definition IAM role should be created | `bool` | `false` | no |
| <a name="input_create_task_exec_policy"></a> [create\_task\_exec\_policy](#input\_create\_task\_exec\_policy) | Determines whether the ECS task definition IAM policy should be created | `bool` | `true` | no |
| <a name="input_default_capacity_provider_strategy"></a> [default\_capacity\_provider\_strategy](#input\_default\_capacity\_provider\_strategy) | Map of default capacity provider strategy definitions to use for the cluster | <pre>map(object({<br/>    base   = optional(number)<br/>    name   = optional(string)<br/>    weight = optional(number)<br/>  }))</pre> | `null` | no |
| <a name="input_infrastructure_iam_role_description"></a> [infrastructure\_iam\_role\_description](#input\_infrastructure\_iam\_role\_description) | Description of the infrastructure IAM role | `string` | `null` | no |
| <a name="input_infrastructure_iam_role_name"></a> [infrastructure\_iam\_role\_name](#input\_infrastructure\_iam\_role\_name) | Name to use on IAM role created for ECS infrastructure | `string` | `null` | no |
| <a name="input_infrastructure_iam_role_path"></a> [infrastructure\_iam\_role\_path](#input\_infrastructure\_iam\_role\_path) | IAM role path for infrastructure role | `string` | `null` | no |
| <a name="input_infrastructure_iam_role_permissions_boundary"></a> [infrastructure\_iam\_role\_permissions\_boundary](#input\_infrastructure\_iam\_role\_permissions\_boundary) | ARN of the policy that is used to set the permissions boundary for the infrastructure IAM role | `string` | `null` | no |
| <a name="input_infrastructure_iam_role_statements"></a> [infrastructure\_iam\_role\_statements](#input\_infrastructure\_iam\_role\_statements) | Map of IAM policy statements for the infrastructure role | `any` | `null` | no |
| <a name="input_infrastructure_iam_role_tags"></a> [infrastructure\_iam\_role\_tags](#input\_infrastructure\_iam\_role\_tags) | Additional tags to add to the infrastructure IAM role | `map(string)` | `{}` | no |
| <a name="input_infrastructure_iam_role_use_name_prefix"></a> [infrastructure\_iam\_role\_use\_name\_prefix](#input\_infrastructure\_iam\_role\_use\_name\_prefix) | Determines whether the IAM role name is used as a prefix | `bool` | `true` | no |
| <a name="input_name"></a> [name](#input\_name) | Name identifier for the ECS cluster (will be prefixed with project-environment) | `string` | `"cluster"` | no |
| <a name="input_node_iam_role_additional_policies"></a> [node\_iam\_role\_additional\_policies](#input\_node\_iam\_role\_additional\_policies) | Additional policies to be added to the node IAM role | `map(string)` | `{}` | no |
| <a name="input_node_iam_role_description"></a> [node\_iam\_role\_description](#input\_node\_iam\_role\_description) | Description of the node IAM role | `string` | `"ECS Managed Instances node IAM role"` | no |
| <a name="input_node_iam_role_name"></a> [node\_iam\_role\_name](#input\_node\_iam\_role\_name) | Name to use on IAM role/instance profile created for ECS nodes | `string` | `null` | no |
| <a name="input_node_iam_role_path"></a> [node\_iam\_role\_path](#input\_node\_iam\_role\_path) | IAM role/instance profile path | `string` | `null` | no |
| <a name="input_node_iam_role_permissions_boundary"></a> [node\_iam\_role\_permissions\_boundary](#input\_node\_iam\_role\_permissions\_boundary) | ARN of the policy that is used to set the permissions boundary for the node IAM role | `string` | `null` | no |
| <a name="input_node_iam_role_statements"></a> [node\_iam\_role\_statements](#input\_node\_iam\_role\_statements) | Map of IAM policy statements for the node role | `any` | `null` | no |
| <a name="input_node_iam_role_tags"></a> [node\_iam\_role\_tags](#input\_node\_iam\_role\_tags) | Additional tags to add to the node IAM role | `map(string)` | `{}` | no |
| <a name="input_node_iam_role_use_name_prefix"></a> [node\_iam\_role\_use\_name\_prefix](#input\_node\_iam\_role\_use\_name\_prefix) | Determines whether the IAM role/instance profile name is used as a prefix | `bool` | `true` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Additional tags to merge with common tags | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_cloudwatch_log_group_arn"></a> [cloudwatch\_log\_group\_arn](#output\_cloudwatch\_log\_group\_arn) | ARN of CloudWatch log group created for the cluster |
| <a name="output_cloudwatch_log_group_name"></a> [cloudwatch\_log\_group\_name](#output\_cloudwatch\_log\_group\_name) | Name of CloudWatch log group created for the cluster |
| <a name="output_cluster_arn"></a> [cluster\_arn](#output\_cluster\_arn) | ARN that identifies the cluster |
| <a name="output_cluster_capacity_providers"></a> [cluster\_capacity\_providers](#output\_cluster\_capacity\_providers) | Map of cluster capacity providers created and their attributes |
| <a name="output_cluster_id"></a> [cluster\_id](#output\_cluster\_id) | ID that identifies the cluster |
| <a name="output_cluster_name"></a> [cluster\_name](#output\_cluster\_name) | Name that identifies the cluster |
| <a name="output_infrastructure_iam_role_arn"></a> [infrastructure\_iam\_role\_arn](#output\_infrastructure\_iam\_role\_arn) | ARN of IAM role created for ECS infrastructure |
| <a name="output_infrastructure_iam_role_name"></a> [infrastructure\_iam\_role\_name](#output\_infrastructure\_iam\_role\_name) | Name of IAM role created for ECS infrastructure |
| <a name="output_infrastructure_iam_role_unique_id"></a> [infrastructure\_iam\_role\_unique\_id](#output\_infrastructure\_iam\_role\_unique\_id) | Stable and unique string identifying the IAM role |
| <a name="output_node_iam_instance_profile_arn"></a> [node\_iam\_instance\_profile\_arn](#output\_node\_iam\_instance\_profile\_arn) | ARN assigned by AWS to the instance profile |
| <a name="output_node_iam_instance_profile_id"></a> [node\_iam\_instance\_profile\_id](#output\_node\_iam\_instance\_profile\_id) | Instance profile's ID |
| <a name="output_node_iam_instance_profile_unique"></a> [node\_iam\_instance\_profile\_unique](#output\_node\_iam\_instance\_profile\_unique) | Stable and unique string identifying the IAM instance profile |
| <a name="output_node_iam_role_arn"></a> [node\_iam\_role\_arn](#output\_node\_iam\_role\_arn) | ARN of IAM role created for ECS nodes |
| <a name="output_node_iam_role_name"></a> [node\_iam\_role\_name](#output\_node\_iam\_role\_name) | Name of IAM role created for ECS nodes |
| <a name="output_node_iam_role_unique_id"></a> [node\_iam\_role\_unique\_id](#output\_node\_iam\_role\_unique\_id) | Stable and unique string identifying the node IAM role |
| <a name="output_task_exec_iam_role_arn"></a> [task\_exec\_iam\_role\_arn](#output\_task\_exec\_iam\_role\_arn) | ARN of IAM role created for ECS task execution |
| <a name="output_task_exec_iam_role_name"></a> [task\_exec\_iam\_role\_name](#output\_task\_exec\_iam\_role\_name) | Name of IAM role created for ECS task execution |
| <a name="output_task_exec_iam_role_unique_id"></a> [task\_exec\_iam\_role\_unique\_id](#output\_task\_exec\_iam\_role\_unique\_id) | Stable and unique string identifying the task execution IAM role |
<!-- END_TF_DOCS -->
