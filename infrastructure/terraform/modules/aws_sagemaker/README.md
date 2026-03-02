<!-- BEGIN_TF_DOCS -->
# SageMaker Module

Native Terraform resources for AWS SageMaker notebook instances.

Standards enforced:
- Naming convention: `{project}-{name}-{environment}`
- VPC placement in private subnets
- Encryption at rest via KMS
- Auto-stop lifecycle configuration for cost control
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

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_iam_role.sagemaker](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.custom_policies](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.sagemaker_full_access](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_sagemaker_notebook_instance.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sagemaker_notebook_instance) | resource |
| [aws_sagemaker_notebook_instance_lifecycle_configuration.auto_stop](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sagemaker_notebook_instance_lifecycle_configuration) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_context"></a> [context](#input\_context) | Context object containing project, environment, region, and common tags | <pre>object({<br/>    project     = string<br/>    environment = string<br/>    region      = string<br/>    common_tags = map(string)<br/>  })</pre> | n/a | yes |
| <a name="input_name"></a> [name](#input\_name) | Name identifier for the notebook instance | `string` | n/a | yes |
| <a name="input_additional_policy_arns"></a> [additional\_policy\_arns](#input\_additional\_policy\_arns) | Additional IAM policy ARNs to attach to the SageMaker role | `list(string)` | `[]` | no |
| <a name="input_attach_full_access_policy"></a> [attach\_full\_access\_policy](#input\_attach\_full\_access\_policy) | Attach AmazonSageMakerFullAccess managed policy | `bool` | `true` | no |
| <a name="input_auto_stop_idle_minutes"></a> [auto\_stop\_idle\_minutes](#input\_auto\_stop\_idle\_minutes) | Auto-stop after N minutes of idle time. Set to 0 to disable | `number` | `60` | no |
| <a name="input_direct_internet_access"></a> [direct\_internet\_access](#input\_direct\_internet\_access) | Whether the notebook has direct internet access | `bool` | `false` | no |
| <a name="input_instance_type"></a> [instance\_type](#input\_instance\_type) | SageMaker notebook instance type | `string` | `"ml.t3.medium"` | no |
| <a name="input_kms_key_id"></a> [kms\_key\_id](#input\_kms\_key\_id) | KMS key ID for encryption at rest | `string` | `null` | no |
| <a name="input_security_group_ids"></a> [security\_group\_ids](#input\_security\_group\_ids) | List of security group IDs | `list(string)` | `[]` | no |
| <a name="input_subnet_id"></a> [subnet\_id](#input\_subnet\_id) | Subnet ID for VPC placement | `string` | `null` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Additional tags to merge with common tags | `map(string)` | `{}` | no |
| <a name="input_volume_size"></a> [volume\_size](#input\_volume\_size) | EBS volume size in GB | `number` | `20` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_notebook_instance_arn"></a> [notebook\_instance\_arn](#output\_notebook\_instance\_arn) | ARN of the SageMaker notebook instance |
| <a name="output_notebook_instance_name"></a> [notebook\_instance\_name](#output\_notebook\_instance\_name) | Name of the SageMaker notebook instance |
| <a name="output_notebook_instance_url"></a> [notebook\_instance\_url](#output\_notebook\_instance\_url) | URL to access the notebook instance |
| <a name="output_sagemaker_role_arn"></a> [sagemaker\_role\_arn](#output\_sagemaker\_role\_arn) | ARN of the SageMaker IAM role |
<!-- END_TF_DOCS -->
