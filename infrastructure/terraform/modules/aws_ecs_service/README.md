<!-- BEGIN_TF_DOCS -->
# AWS ECS Service Module

Thin wrapper around [terraform-aws-modules/ecs/aws](https://registry.terraform.io/modules/terraform-aws-modules/ecs/aws/latest).

This module provides organization-wide standards for ECS services:
- Support for both Fargate and EC2 launch types
- Task definitions with container definitions
- Load balancer integration (ALB/NLB)
- Auto-scaling configuration
- Service Connect and Service Discovery
- IAM roles for tasks and task execution
- Security groups and network configuration
- CloudWatch logging
- Standard naming and tagging conventions

## Usage

```hcl
module "example" {
  source = "../modules/this-module"
  
  context = {
    project     = "my-project"
    environment = "dev"
    region      = "us-east-1"
    common_tags = {
      Environment = "dev"
      ManagedBy   = "terraform"
    }
  }
  
  # Add required variables here
}
```

## Requirements

No requirements.

## Providers

No providers.

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_ecs_service"></a> [ecs\_service](#module\_ecs\_service) | terraform-aws-modules/ecs/aws//modules/service | ~> 7.3 |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_cluster_arn"></a> [cluster\_arn](#input\_cluster\_arn) | ARN of the ECS cluster where the service will be deployed | `string` | n/a | yes |
| <a name="input_container_definitions"></a> [container\_definitions](#input\_container\_definitions) | Map of container definitions to create | `any` | n/a | yes |
| <a name="input_context"></a> [context](#input\_context) | Context object containing project, environment, region, and common tags | <pre>object({<br/>    project     = string<br/>    environment = string<br/>    region      = string<br/>    common_tags = map(string)<br/>  })</pre> | n/a | yes |
| <a name="input_name"></a> [name](#input\_name) | Name identifier for the ECS service (will be prefixed with project-environment) | `string` | n/a | yes |
| <a name="input_subnet_ids"></a> [subnet\_ids](#input\_subnet\_ids) | List of subnet IDs to associate with the task or service | `list(string)` | n/a | yes |
| <a name="input_assign_public_ip"></a> [assign\_public\_ip](#input\_assign\_public\_ip) | Assign a public IP address to the ENI | `bool` | `false` | no |
| <a name="input_autoscaling_max_capacity"></a> [autoscaling\_max\_capacity](#input\_autoscaling\_max\_capacity) | Maximum number of tasks to run in your service | `number` | `10` | no |
| <a name="input_autoscaling_min_capacity"></a> [autoscaling\_min\_capacity](#input\_autoscaling\_min\_capacity) | Minimum number of tasks to run in your service | `number` | `1` | no |
| <a name="input_autoscaling_policies"></a> [autoscaling\_policies](#input\_autoscaling\_policies) | Map of autoscaling policies to create for the service | `any` | `{}` | no |
| <a name="input_autoscaling_scheduled_actions"></a> [autoscaling\_scheduled\_actions](#input\_autoscaling\_scheduled\_actions) | Map of autoscaling scheduled actions to create for the service | `any` | `{}` | no |
| <a name="input_capacity_provider_strategy"></a> [capacity\_provider\_strategy](#input\_capacity\_provider\_strategy) | Capacity provider strategy to use for the service | <pre>map(object({<br/>    base              = optional(number)<br/>    capacity_provider = string<br/>    weight            = optional(number)<br/>  }))</pre> | `null` | no |
| <a name="input_cpu"></a> [cpu](#input\_cpu) | Number of CPU units used by the task | `number` | `256` | no |
| <a name="input_create_iam_role"></a> [create\_iam\_role](#input\_create\_iam\_role) | Determines whether the ECS service IAM role should be created | `bool` | `false` | no |
| <a name="input_create_security_group"></a> [create\_security\_group](#input\_create\_security\_group) | Determines whether to create a security group for the service | `bool` | `true` | no |
| <a name="input_create_task_definition"></a> [create\_task\_definition](#input\_create\_task\_definition) | Determines whether to create a task definition or use existing | `bool` | `true` | no |
| <a name="input_create_task_exec_iam_role"></a> [create\_task\_exec\_iam\_role](#input\_create\_task\_exec\_iam\_role) | Determines whether the ECS task execution IAM role should be created | `bool` | `true` | no |
| <a name="input_create_tasks_iam_role"></a> [create\_tasks\_iam\_role](#input\_create\_tasks\_iam\_role) | Determines whether the ECS tasks IAM role should be created | `bool` | `true` | no |
| <a name="input_deployment_circuit_breaker"></a> [deployment\_circuit\_breaker](#input\_deployment\_circuit\_breaker) | Configuration block for deployment circuit breaker | <pre>object({<br/>    enable   = bool<br/>    rollback = bool<br/>  })</pre> | `null` | no |
| <a name="input_deployment_controller"></a> [deployment\_controller](#input\_deployment\_controller) | Configuration block for deployment controller | <pre>object({<br/>    type = optional(string)<br/>  })</pre> | `null` | no |
| <a name="input_deployment_maximum_percent"></a> [deployment\_maximum\_percent](#input\_deployment\_maximum\_percent) | Upper limit on the number of running tasks that can be running during deployment | `number` | `200` | no |
| <a name="input_deployment_minimum_healthy_percent"></a> [deployment\_minimum\_healthy\_percent](#input\_deployment\_minimum\_healthy\_percent) | Lower limit on the number of running tasks that must remain healthy during deployment | `number` | `100` | no |
| <a name="input_desired_count"></a> [desired\_count](#input\_desired\_count) | Number of instances of the task definition to place and keep running | `number` | `1` | no |
| <a name="input_enable_autoscaling"></a> [enable\_autoscaling](#input\_enable\_autoscaling) | Determines whether to enable autoscaling for the service | `bool` | `false` | no |
| <a name="input_enable_ecs_managed_tags"></a> [enable\_ecs\_managed\_tags](#input\_enable\_ecs\_managed\_tags) | Specifies whether to enable Amazon ECS managed tags for the tasks within the service | `bool` | `true` | no |
| <a name="input_enable_execute_command"></a> [enable\_execute\_command](#input\_enable\_execute\_command) | Specifies whether to enable Amazon ECS Exec for the tasks within the service | `bool` | `false` | no |
| <a name="input_ephemeral_storage"></a> [ephemeral\_storage](#input\_ephemeral\_storage) | The amount of ephemeral storage to allocate for the task (in GiB) | <pre>object({<br/>    size_in_gib = number<br/>  })</pre> | `null` | no |
| <a name="input_force_new_deployment"></a> [force\_new\_deployment](#input\_force\_new\_deployment) | Enable to force a new task deployment of the service | `bool` | `false` | no |
| <a name="input_health_check_grace_period_seconds"></a> [health\_check\_grace\_period\_seconds](#input\_health\_check\_grace\_period\_seconds) | Seconds to ignore failing load balancer health checks on newly instantiated tasks | `number` | `null` | no |
| <a name="input_iam_role_arn"></a> [iam\_role\_arn](#input\_iam\_role\_arn) | ARN of existing IAM role to use for the service | `string` | `null` | no |
| <a name="input_iam_role_description"></a> [iam\_role\_description](#input\_iam\_role\_description) | Description of the IAM role | `string` | `null` | no |
| <a name="input_iam_role_name"></a> [iam\_role\_name](#input\_iam\_role\_name) | Name to use on IAM role created for the service | `string` | `null` | no |
| <a name="input_iam_role_path"></a> [iam\_role\_path](#input\_iam\_role\_path) | IAM role path | `string` | `null` | no |
| <a name="input_iam_role_permissions_boundary"></a> [iam\_role\_permissions\_boundary](#input\_iam\_role\_permissions\_boundary) | ARN of the policy that is used to set the permissions boundary for the IAM role | `string` | `null` | no |
| <a name="input_iam_role_statements"></a> [iam\_role\_statements](#input\_iam\_role\_statements) | Map of IAM policy statements for the service IAM role | `any` | `null` | no |
| <a name="input_iam_role_tags"></a> [iam\_role\_tags](#input\_iam\_role\_tags) | Additional tags to add to the service IAM role | `map(string)` | `{}` | no |
| <a name="input_iam_role_use_name_prefix"></a> [iam\_role\_use\_name\_prefix](#input\_iam\_role\_use\_name\_prefix) | Determines whether the IAM role name is used as a prefix | `bool` | `true` | no |
| <a name="input_launch_type"></a> [launch\_type](#input\_launch\_type) | Launch type on which to run service. Valid values are EC2, FARGATE, or EXTERNAL | `string` | `"FARGATE"` | no |
| <a name="input_load_balancer"></a> [load\_balancer](#input\_load\_balancer) | Configuration block for load balancers | <pre>map(object({<br/>    container_name   = string<br/>    container_port   = number<br/>    elb_name         = optional(string)<br/>    target_group_arn = optional(string)<br/>  }))</pre> | `{}` | no |
| <a name="input_memory"></a> [memory](#input\_memory) | Amount (in MiB) of memory used by the task | `number` | `512` | no |
| <a name="input_platform_version"></a> [platform\_version](#input\_platform\_version) | Platform version on which to run your service (only applicable for FARGATE launch type) | `string` | `"LATEST"` | no |
| <a name="input_propagate_tags"></a> [propagate\_tags](#input\_propagate\_tags) | Specifies whether to propagate the tags from the task definition or the service to the tasks | `string` | `"SERVICE"` | no |
| <a name="input_requires_compatibilities"></a> [requires\_compatibilities](#input\_requires\_compatibilities) | Set of launch types required by the task. Valid values are EC2 and FARGATE | `list(string)` | <pre>[<br/>  "FARGATE"<br/>]</pre> | no |
| <a name="input_security_group_description"></a> [security\_group\_description](#input\_security\_group\_description) | Description of the security group created | `string` | `null` | no |
| <a name="input_security_group_egress_rules"></a> [security\_group\_egress\_rules](#input\_security\_group\_egress\_rules) | Security group egress rules to add to the security group created | `any` | <pre>{<br/>  "all_ipv4": {<br/>    "cidr_ipv4": "0.0.0.0/0",<br/>    "description": "Allow all IPv4 traffic",<br/>    "ip_protocol": "-1"<br/>  }<br/>}</pre> | no |
| <a name="input_security_group_ids"></a> [security\_group\_ids](#input\_security\_group\_ids) | List of security group IDs to associate with the task or service | `list(string)` | `[]` | no |
| <a name="input_security_group_ingress_rules"></a> [security\_group\_ingress\_rules](#input\_security\_group\_ingress\_rules) | Security group ingress rules to add to the security group created | `any` | `{}` | no |
| <a name="input_security_group_name"></a> [security\_group\_name](#input\_security\_group\_name) | Name to use on security group created | `string` | `null` | no |
| <a name="input_security_group_tags"></a> [security\_group\_tags](#input\_security\_group\_tags) | Additional tags to add to the security group | `map(string)` | `{}` | no |
| <a name="input_security_group_use_name_prefix"></a> [security\_group\_use\_name\_prefix](#input\_security\_group\_use\_name\_prefix) | Determines whether the security group name is used as a prefix | `bool` | `true` | no |
| <a name="input_service_connect_configuration"></a> [service\_connect\_configuration](#input\_service\_connect\_configuration) | Configuration block for Service Connect | <pre>object({<br/>    enabled = optional(bool)<br/>    log_configuration = optional(object({<br/>      log_driver = string<br/>      options    = optional(map(string))<br/>      secret_option = optional(list(object({<br/>        name       = string<br/>        value_from = string<br/>      })))<br/>    }))<br/>    namespace = optional(string)<br/>    service = optional(list(object({<br/>      client_alias = optional(object({<br/>        dns_name = optional(string)<br/>        port     = number<br/>      }))<br/>      discovery_name        = optional(string)<br/>      ingress_port_override = optional(number)<br/>      port_name             = string<br/>    })))<br/>  })</pre> | `null` | no |
| <a name="input_service_registries"></a> [service\_registries](#input\_service\_registries) | Service discovery registries for the service | <pre>object({<br/>    container_name = optional(string)<br/>    container_port = optional(number)<br/>    port           = optional(number)<br/>    registry_arn   = string<br/>  })</pre> | `null` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Additional tags to merge with common tags | `map(string)` | `{}` | no |
| <a name="input_task_definition_arn"></a> [task\_definition\_arn](#input\_task\_definition\_arn) | ARN of existing task definition to use (if create\_task\_definition is false) | `string` | `null` | no |
| <a name="input_task_exec_iam_role_arn"></a> [task\_exec\_iam\_role\_arn](#input\_task\_exec\_iam\_role\_arn) | ARN of existing IAM role to use for task execution | `string` | `null` | no |
| <a name="input_task_exec_iam_role_description"></a> [task\_exec\_iam\_role\_description](#input\_task\_exec\_iam\_role\_description) | Description of the task execution IAM role | `string` | `null` | no |
| <a name="input_task_exec_iam_role_name"></a> [task\_exec\_iam\_role\_name](#input\_task\_exec\_iam\_role\_name) | Name to use on IAM role created for task execution | `string` | `null` | no |
| <a name="input_task_exec_iam_role_path"></a> [task\_exec\_iam\_role\_path](#input\_task\_exec\_iam\_role\_path) | IAM role path | `string` | `null` | no |
| <a name="input_task_exec_iam_role_permissions_boundary"></a> [task\_exec\_iam\_role\_permissions\_boundary](#input\_task\_exec\_iam\_role\_permissions\_boundary) | ARN of the policy that is used to set the permissions boundary for the task execution IAM role | `string` | `null` | no |
| <a name="input_task_exec_iam_role_policies"></a> [task\_exec\_iam\_role\_policies](#input\_task\_exec\_iam\_role\_policies) | Map of IAM policies to attach to the task execution IAM role | `map(string)` | `{}` | no |
| <a name="input_task_exec_iam_role_statements"></a> [task\_exec\_iam\_role\_statements](#input\_task\_exec\_iam\_role\_statements) | Map of IAM policy statements for the task execution IAM role | `any` | `null` | no |
| <a name="input_task_exec_iam_role_tags"></a> [task\_exec\_iam\_role\_tags](#input\_task\_exec\_iam\_role\_tags) | Additional tags to add to the task execution IAM role | `map(string)` | `{}` | no |
| <a name="input_task_exec_iam_role_use_name_prefix"></a> [task\_exec\_iam\_role\_use\_name\_prefix](#input\_task\_exec\_iam\_role\_use\_name\_prefix) | Determines whether the IAM role name is used as a prefix | `bool` | `true` | no |
| <a name="input_task_exec_secret_arns"></a> [task\_exec\_secret\_arns](#input\_task\_exec\_secret\_arns) | List of Secrets Manager secret ARNs the task execution role will be permitted to get/read | `list(string)` | `[]` | no |
| <a name="input_task_exec_ssm_param_arns"></a> [task\_exec\_ssm\_param\_arns](#input\_task\_exec\_ssm\_param\_arns) | List of SSM parameter ARNs the task execution role will be permitted to get/read | `list(string)` | `[]` | no |
| <a name="input_tasks_iam_role_arn"></a> [tasks\_iam\_role\_arn](#input\_tasks\_iam\_role\_arn) | ARN of existing IAM role to use for tasks | `string` | `null` | no |
| <a name="input_tasks_iam_role_description"></a> [tasks\_iam\_role\_description](#input\_tasks\_iam\_role\_description) | Description of the tasks IAM role | `string` | `null` | no |
| <a name="input_tasks_iam_role_name"></a> [tasks\_iam\_role\_name](#input\_tasks\_iam\_role\_name) | Name to use on IAM role created for tasks | `string` | `null` | no |
| <a name="input_tasks_iam_role_path"></a> [tasks\_iam\_role\_path](#input\_tasks\_iam\_role\_path) | IAM role path | `string` | `null` | no |
| <a name="input_tasks_iam_role_permissions_boundary"></a> [tasks\_iam\_role\_permissions\_boundary](#input\_tasks\_iam\_role\_permissions\_boundary) | ARN of the policy that is used to set the permissions boundary for the tasks IAM role | `string` | `null` | no |
| <a name="input_tasks_iam_role_policies"></a> [tasks\_iam\_role\_policies](#input\_tasks\_iam\_role\_policies) | Map of IAM policies to attach to the tasks IAM role | `map(string)` | `{}` | no |
| <a name="input_tasks_iam_role_statements"></a> [tasks\_iam\_role\_statements](#input\_tasks\_iam\_role\_statements) | Map of IAM policy statements for the tasks IAM role | `any` | `null` | no |
| <a name="input_tasks_iam_role_tags"></a> [tasks\_iam\_role\_tags](#input\_tasks\_iam\_role\_tags) | Additional tags to add to the tasks IAM role | `map(string)` | `{}` | no |
| <a name="input_tasks_iam_role_use_name_prefix"></a> [tasks\_iam\_role\_use\_name\_prefix](#input\_tasks\_iam\_role\_use\_name\_prefix) | Determines whether the IAM role name is used as a prefix | `bool` | `true` | no |
| <a name="input_volume"></a> [volume](#input\_volume) | Configuration block for volumes that containers in your task may use | `any` | `{}` | no |
| <a name="input_wait_for_steady_state"></a> [wait\_for\_steady\_state](#input\_wait\_for\_steady\_state) | Wait for the service to reach a steady state before Terraform considers the operation complete | `bool` | `false` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_autoscaling_policies"></a> [autoscaling\_policies](#output\_autoscaling\_policies) | Map of autoscaling policies and their attributes |
| <a name="output_autoscaling_scheduled_actions"></a> [autoscaling\_scheduled\_actions](#output\_autoscaling\_scheduled\_actions) | Map of autoscaling scheduled actions and their attributes |
| <a name="output_autoscaling_target_arn"></a> [autoscaling\_target\_arn](#output\_autoscaling\_target\_arn) | ARN of the autoscaling target |
| <a name="output_container_definitions"></a> [container\_definitions](#output\_container\_definitions) | Container definitions used for the task definition |
| <a name="output_iam_role_arn"></a> [iam\_role\_arn](#output\_iam\_role\_arn) | ARN of the service IAM role |
| <a name="output_iam_role_name"></a> [iam\_role\_name](#output\_iam\_role\_name) | Name of the service IAM role |
| <a name="output_security_group_arn"></a> [security\_group\_arn](#output\_security\_group\_arn) | ARN of the security group created for the service |
| <a name="output_security_group_id"></a> [security\_group\_id](#output\_security\_group\_id) | ID of the security group created for the service |
| <a name="output_service_id"></a> [service\_id](#output\_service\_id) | ARN that identifies the service |
| <a name="output_service_name"></a> [service\_name](#output\_service\_name) | Name of the service |
| <a name="output_task_definition_arn"></a> [task\_definition\_arn](#output\_task\_definition\_arn) | Full ARN of the Task Definition (including both family and revision) |
| <a name="output_task_definition_family"></a> [task\_definition\_family](#output\_task\_definition\_family) | Family of the Task Definition |
| <a name="output_task_definition_revision"></a> [task\_definition\_revision](#output\_task\_definition\_revision) | Revision of the task in a particular family |
| <a name="output_task_exec_iam_role_arn"></a> [task\_exec\_iam\_role\_arn](#output\_task\_exec\_iam\_role\_arn) | ARN of the task execution IAM role |
| <a name="output_task_exec_iam_role_name"></a> [task\_exec\_iam\_role\_name](#output\_task\_exec\_iam\_role\_name) | Name of the task execution IAM role |
| <a name="output_tasks_iam_role_arn"></a> [tasks\_iam\_role\_arn](#output\_tasks\_iam\_role\_arn) | ARN of the tasks IAM role |
| <a name="output_tasks_iam_role_name"></a> [tasks\_iam\_role\_name](#output\_tasks\_iam\_role\_name) | Name of the tasks IAM role |
<!-- END_TF_DOCS -->