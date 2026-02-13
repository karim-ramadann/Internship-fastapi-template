<!-- BEGIN_TF_DOCS -->
# AWS Batch Module

Thin wrapper around [terraform-aws-modules/batch/aws](https://registry.terraform.io/modules/terraform-aws-modules/batch/aws/latest).

This module provides organization-wide standards for AWS Batch:
- Compute environments (EC2, EC2 Spot, Fargate, Fargate Spot)
- Job queues with priority and scheduling policies
- Job definitions for containerized batch workloads
- IAM roles for service, instance, and spot fleet
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
| <a name="module_batch"></a> [batch](#module\_batch) | terraform-aws-modules/batch/aws | ~> 3.0 |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_context"></a> [context](#input\_context) | Context object containing project, environment, region, and common tags | <pre>object({<br/>    project     = string<br/>    environment = string<br/>    region      = string<br/>    common_tags = map(string)<br/>  })</pre> | n/a | yes |
| <a name="input_compute_environments"></a> [compute\_environments](#input\_compute\_environments) | Map of compute environment definitions to create | `any` | `null` | no |
| <a name="input_create_instance_iam_role"></a> [create\_instance\_iam\_role](#input\_create\_instance\_iam\_role) | Determines whether an IAM role is created or to use an existing IAM role for compute instances | `bool` | `true` | no |
| <a name="input_create_job_queues"></a> [create\_job\_queues](#input\_create\_job\_queues) | Determines whether to create job queues | `bool` | `true` | no |
| <a name="input_create_service_iam_role"></a> [create\_service\_iam\_role](#input\_create\_service\_iam\_role) | Determines whether an IAM role is created or to use an existing IAM role for the Batch service | `bool` | `true` | no |
| <a name="input_create_spot_fleet_iam_role"></a> [create\_spot\_fleet\_iam\_role](#input\_create\_spot\_fleet\_iam\_role) | Determines whether an IAM role is created or to use an existing IAM role for spot fleet | `bool` | `false` | no |
| <a name="input_instance_iam_role_additional_policies"></a> [instance\_iam\_role\_additional\_policies](#input\_instance\_iam\_role\_additional\_policies) | Additional policies to be added to the instance IAM role | `map(string)` | `{}` | no |
| <a name="input_instance_iam_role_description"></a> [instance\_iam\_role\_description](#input\_instance\_iam\_role\_description) | Compute instance IAM role description | `string` | `null` | no |
| <a name="input_instance_iam_role_name"></a> [instance\_iam\_role\_name](#input\_instance\_iam\_role\_name) | Compute instance IAM role name | `string` | `null` | no |
| <a name="input_instance_iam_role_path"></a> [instance\_iam\_role\_path](#input\_instance\_iam\_role\_path) | Compute instance IAM role path | `string` | `null` | no |
| <a name="input_instance_iam_role_permissions_boundary"></a> [instance\_iam\_role\_permissions\_boundary](#input\_instance\_iam\_role\_permissions\_boundary) | ARN of the policy that is used to set the permissions boundary for the instance IAM role | `string` | `null` | no |
| <a name="input_instance_iam_role_tags"></a> [instance\_iam\_role\_tags](#input\_instance\_iam\_role\_tags) | Additional tags to add to the instance IAM role | `map(string)` | `{}` | no |
| <a name="input_instance_iam_role_use_name_prefix"></a> [instance\_iam\_role\_use\_name\_prefix](#input\_instance\_iam\_role\_use\_name\_prefix) | Determines whether the IAM role name is used as a prefix | `bool` | `true` | no |
| <a name="input_job_definitions"></a> [job\_definitions](#input\_job\_definitions) | Map of job definitions to create | `any` | `null` | no |
| <a name="input_job_queues"></a> [job\_queues](#input\_job\_queues) | Map of job queue and scheduling policy definitions to create | `any` | `null` | no |
| <a name="input_service_iam_role_additional_policies"></a> [service\_iam\_role\_additional\_policies](#input\_service\_iam\_role\_additional\_policies) | Additional policies to be added to the service IAM role | `map(string)` | `{}` | no |
| <a name="input_service_iam_role_description"></a> [service\_iam\_role\_description](#input\_service\_iam\_role\_description) | Batch service IAM role description | `string` | `null` | no |
| <a name="input_service_iam_role_name"></a> [service\_iam\_role\_name](#input\_service\_iam\_role\_name) | Batch service IAM role name | `string` | `null` | no |
| <a name="input_service_iam_role_path"></a> [service\_iam\_role\_path](#input\_service\_iam\_role\_path) | Batch service IAM role path | `string` | `null` | no |
| <a name="input_service_iam_role_permissions_boundary"></a> [service\_iam\_role\_permissions\_boundary](#input\_service\_iam\_role\_permissions\_boundary) | ARN of the policy that is used to set the permissions boundary for the service IAM role | `string` | `null` | no |
| <a name="input_service_iam_role_tags"></a> [service\_iam\_role\_tags](#input\_service\_iam\_role\_tags) | Additional tags to add to the service IAM role | `map(string)` | `{}` | no |
| <a name="input_service_iam_role_use_name_prefix"></a> [service\_iam\_role\_use\_name\_prefix](#input\_service\_iam\_role\_use\_name\_prefix) | Determines whether the IAM role name is used as a prefix | `bool` | `true` | no |
| <a name="input_spot_fleet_iam_role_additional_policies"></a> [spot\_fleet\_iam\_role\_additional\_policies](#input\_spot\_fleet\_iam\_role\_additional\_policies) | Additional policies to be added to the spot fleet IAM role | `map(string)` | `{}` | no |
| <a name="input_spot_fleet_iam_role_description"></a> [spot\_fleet\_iam\_role\_description](#input\_spot\_fleet\_iam\_role\_description) | Spot fleet IAM role description | `string` | `null` | no |
| <a name="input_spot_fleet_iam_role_name"></a> [spot\_fleet\_iam\_role\_name](#input\_spot\_fleet\_iam\_role\_name) | Spot fleet IAM role name | `string` | `null` | no |
| <a name="input_spot_fleet_iam_role_path"></a> [spot\_fleet\_iam\_role\_path](#input\_spot\_fleet\_iam\_role\_path) | Spot fleet IAM role path | `string` | `null` | no |
| <a name="input_spot_fleet_iam_role_permissions_boundary"></a> [spot\_fleet\_iam\_role\_permissions\_boundary](#input\_spot\_fleet\_iam\_role\_permissions\_boundary) | ARN of the policy that is used to set the permissions boundary for the spot fleet IAM role | `string` | `null` | no |
| <a name="input_spot_fleet_iam_role_tags"></a> [spot\_fleet\_iam\_role\_tags](#input\_spot\_fleet\_iam\_role\_tags) | Additional tags to add to the spot fleet IAM role | `map(string)` | `{}` | no |
| <a name="input_spot_fleet_iam_role_use_name_prefix"></a> [spot\_fleet\_iam\_role\_use\_name\_prefix](#input\_spot\_fleet\_iam\_role\_use\_name\_prefix) | Determines whether the IAM role name is used as a prefix | `bool` | `true` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Additional tags to merge with common tags | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_compute_environments"></a> [compute\_environments](#output\_compute\_environments) | Map of compute environments created and their associated attributes |
| <a name="output_instance_iam_instance_profile_arn"></a> [instance\_iam\_instance\_profile\_arn](#output\_instance\_iam\_instance\_profile\_arn) | ARN assigned by AWS to the instance profile |
| <a name="output_instance_iam_role_arn"></a> [instance\_iam\_role\_arn](#output\_instance\_iam\_role\_arn) | The Amazon Resource Name (ARN) specifying the instance IAM role |
| <a name="output_instance_iam_role_name"></a> [instance\_iam\_role\_name](#output\_instance\_iam\_role\_name) | The name of the instance IAM role |
| <a name="output_job_definitions"></a> [job\_definitions](#output\_job\_definitions) | Map of job definitions created and their associated attributes |
| <a name="output_job_queues"></a> [job\_queues](#output\_job\_queues) | Map of job queues created and their associated attributes |
| <a name="output_scheduling_policies"></a> [scheduling\_policies](#output\_scheduling\_policies) | Map of scheduling policies created and their associated attributes |
| <a name="output_service_iam_role_arn"></a> [service\_iam\_role\_arn](#output\_service\_iam\_role\_arn) | The Amazon Resource Name (ARN) specifying the service IAM role |
| <a name="output_service_iam_role_name"></a> [service\_iam\_role\_name](#output\_service\_iam\_role\_name) | The name of the service IAM role |
| <a name="output_spot_fleet_iam_role_arn"></a> [spot\_fleet\_iam\_role\_arn](#output\_spot\_fleet\_iam\_role\_arn) | The Amazon Resource Name (ARN) specifying the spot fleet IAM role |
| <a name="output_spot_fleet_iam_role_name"></a> [spot\_fleet\_iam\_role\_name](#output\_spot\_fleet\_iam\_role\_name) | The name of the spot fleet IAM role |
<!-- END_TF_DOCS -->