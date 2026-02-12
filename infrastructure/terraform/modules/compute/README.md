<!-- BEGIN_TF_DOCS -->
## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | n/a |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_autoscaling"></a> [autoscaling](#module\_autoscaling) | terraform-aws-modules/autoscaling/aws | ~> 7.0 |

## Resources

| Name | Type |
|------|------|
| [aws_ecs_capacity_provider.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_capacity_provider) | resource |
| [aws_ecs_cluster.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_cluster) | resource |
| [aws_ecs_cluster_capacity_providers.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_cluster_capacity_providers) | resource |
| [aws_launch_template.ecs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/launch_template) | resource |
| [aws_ami.ecs_optimized](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ami) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_context"></a> [context](#input\_context) | Context object containing project, environment, region, and common tags | <pre>object({<br/>    project     = string<br/>    environment = string<br/>    region      = string<br/>    common_tags = map(string)<br/>  })</pre> | n/a | yes |
| <a name="input_ecs_instance_profile_name"></a> [ecs\_instance\_profile\_name](#input\_ecs\_instance\_profile\_name) | Name of the IAM instance profile for ECS EC2 instances | `string` | n/a | yes |
| <a name="input_ecs_security_group_id"></a> [ecs\_security\_group\_id](#input\_ecs\_security\_group\_id) | ID of the security group for ECS instances | `string` | n/a | yes |
| <a name="input_private_subnet_ids"></a> [private\_subnet\_ids](#input\_private\_subnet\_ids) | List of private subnet IDs for ECS instances | `list(string)` | n/a | yes |
| <a name="input_asg_desired_capacity"></a> [asg\_desired\_capacity](#input\_asg\_desired\_capacity) | Desired capacity of the Auto Scaling Group | `number` | `1` | no |
| <a name="input_asg_max_size"></a> [asg\_max\_size](#input\_asg\_max\_size) | Maximum size of the Auto Scaling Group | `number` | `3` | no |
| <a name="input_asg_min_size"></a> [asg\_min\_size](#input\_asg\_min\_size) | Minimum size of the Auto Scaling Group | `number` | `1` | no |
| <a name="input_capacity_provider_target"></a> [capacity\_provider\_target](#input\_capacity\_provider\_target) | Target capacity percentage for the ECS capacity provider | `number` | `100` | no |
| <a name="input_enable_container_insights"></a> [enable\_container\_insights](#input\_enable\_container\_insights) | Enable CloudWatch Container Insights for the cluster | `bool` | `true` | no |
| <a name="input_instance_type"></a> [instance\_type](#input\_instance\_type) | EC2 instance type for ECS cluster | `string` | `"t3.medium"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_autoscaling_group_arn"></a> [autoscaling\_group\_arn](#output\_autoscaling\_group\_arn) | ARN of the Auto Scaling Group |
| <a name="output_autoscaling_group_id"></a> [autoscaling\_group\_id](#output\_autoscaling\_group\_id) | ID of the Auto Scaling Group |
| <a name="output_autoscaling_group_name"></a> [autoscaling\_group\_name](#output\_autoscaling\_group\_name) | Name of the Auto Scaling Group |
| <a name="output_capacity_provider_name"></a> [capacity\_provider\_name](#output\_capacity\_provider\_name) | Name of the ECS capacity provider |
| <a name="output_cluster_arn"></a> [cluster\_arn](#output\_cluster\_arn) | ARN of the ECS cluster |
| <a name="output_cluster_id"></a> [cluster\_id](#output\_cluster\_id) | ID of the ECS cluster |
| <a name="output_cluster_name"></a> [cluster\_name](#output\_cluster\_name) | Name of the ECS cluster |
<!-- END_TF_DOCS -->