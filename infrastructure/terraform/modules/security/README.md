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
