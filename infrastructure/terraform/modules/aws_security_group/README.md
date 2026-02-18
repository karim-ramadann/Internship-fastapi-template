# AWS Security Group Module

Thin wrapper around [terraform-aws-modules/security-group/aws](https://registry.terraform.io/modules/terraform-aws-modules/security-group/aws/latest).

## Features

- Simplified ingress and egress rule definitions
- Support for CIDR blocks, security groups, and prefix lists
- Automatic security group rule creation
- Computed rules for dynamic configurations
- Standard naming and tagging conventions

## Usage

```hcl
module "alb_security_group" {
  source = "../modules/aws_security_group"

  context     = local.context
  name        = "alb-sg"
  description = "Security group for Application Load Balancer"
  vpc_id      = module.vpc.vpc_id

  ingress_with_cidr_blocks = [
    {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = "0.0.0.0/0"
      description = "HTTP from anywhere"
    },
    {
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = "0.0.0.0/0"
      description = "HTTPS from anywhere"
    }
  ]

  egress_with_cidr_blocks = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = "0.0.0.0/0"
      description = "Allow all outbound"
    }
  ]
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.0 |
| aws | >= 5.0 |

## Providers

Uses terraform-aws-modules/security-group/aws version ~> 5.0

## Naming Convention

- Security Group Name: `{project}-{name}-{environment}` (e.g., `myproject-alb-sg-dev`)

## Outputs

- `security_group_id` - The ID of the security group
- `security_group_arn` - The ARN of the security group
- `security_group_name` - The name of the security group
