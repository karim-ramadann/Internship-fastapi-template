# Security Module

Security groups and IAM roles for ALB, RDS, Lambda, and Step Functions.

## What it does

- ALB security group (HTTP/HTTPS ingress from anywhere, all egress)
- RDS security group (ingress rules added externally by `ecs-fargate` and Lambda)
- Lambda security group (HTTPS/HTTP egress, RDS ingress/egress rules)
- Lambda execution IAM role with VPC access, SSM, and Secrets Manager permissions
- Step Functions execution IAM role with Lambda invoke and CloudWatch Logs permissions

ECS-related security groups and IAM roles are managed by the `ecs-fargate` module, not here.

## Usage

```hcl
module "security" {
  source = "./modules/security"

  context = local.context
  vpc_id  = module.networking.vpc_id
}
```

## Inputs

See [variables.tf](./variables.tf) for the full list.

## Outputs

See [outputs.tf](./outputs.tf) for the full list.

## Upstream Module

- [terraform-aws-modules/security-group/aws](https://registry.terraform.io/modules/terraform-aws-modules/security-group/aws/latest)

<!-- BEGIN_TF_DOCS -->
# Security Module

Security groups and IAM roles for ALB, RDS, Lambda, and Step Functions.

## What it does

- ALB security group (HTTP/HTTPS ingress from anywhere, all egress)
- RDS security group (ingress rules added externally by `ecs-fargate` and Lambda)
- Lambda security group (HTTPS/HTTP egress, RDS ingress/egress rules)
- Lambda execution IAM role with VPC access, SSM, and Secrets Manager permissions
- Step Functions execution IAM role with Lambda invoke and CloudWatch Logs permissions

ECS-related security groups and IAM roles are managed by the `ecs-fargate` module, not here.

## Usage

```hcl
module "security" {
  source = "./modules/security"

  context = local.context
  vpc_id  = module.networking.vpc_id
}
```

## Inputs

See [variables.tf](./variables.tf) for the full list.

## Outputs

See [outputs.tf](./outputs.tf) for the full list.

## Upstream Module

- [terraform-aws-modules/security-group/aws](https://registry.terraform.io/modules/terraform-aws-modules/security-group/aws/latest)

## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | n/a |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_alb_security_group"></a> [alb\_security\_group](#module\_alb\_security\_group) | terraform-aws-modules/security-group/aws | ~> 5.0 |
| <a name="module_lambda_security_group"></a> [lambda\_security\_group](#module\_lambda\_security\_group) | terraform-aws-modules/security-group/aws | ~> 5.0 |
| <a name="module_rds_security_group"></a> [rds\_security\_group](#module\_rds\_security\_group) | terraform-aws-modules/security-group/aws | ~> 5.0 |

## Resources

| Name | Type |
|------|------|
| [aws_iam_policy.lambda_ssm](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.step_functions_lambda](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_role.lambda_execution_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.step_functions_execution_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.lambda_ssm](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.lambda_vpc_execution](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.step_functions_lambda](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_security_group_rule.lambda_to_rds](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.lambda_to_rds_egress](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_iam_policy_document.lambda_assume_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.lambda_ssm](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.step_functions_assume_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.step_functions_lambda](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_context"></a> [context](#input\_context) | Context object containing project, environment, region, and common tags | <pre>object({<br/>    project     = string<br/>    environment = string<br/>    region      = string<br/>    common_tags = map(string)<br/>  })</pre> | n/a | yes |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | ID of the VPC | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_alb_security_group_id"></a> [alb\_security\_group\_id](#output\_alb\_security\_group\_id) | ID of the ALB security group |
| <a name="output_lambda_execution_role_arn"></a> [lambda\_execution\_role\_arn](#output\_lambda\_execution\_role\_arn) | ARN of Lambda execution IAM role |
| <a name="output_lambda_security_group_id"></a> [lambda\_security\_group\_id](#output\_lambda\_security\_group\_id) | ID of Lambda security group |
| <a name="output_rds_security_group_id"></a> [rds\_security\_group\_id](#output\_rds\_security\_group\_id) | ID of the RDS security group |
| <a name="output_step_functions_execution_role_arn"></a> [step\_functions\_execution\_role\_arn](#output\_step\_functions\_execution\_role\_arn) | ARN of Step Functions execution IAM role |
<!-- END_TF_DOCS -->