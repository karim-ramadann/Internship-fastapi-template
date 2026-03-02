# AWS Application Load Balancer Module

Thin wrapper around [terraform-aws-modules/alb/aws](https://registry.terraform.io/modules/terraform-aws-modules/alb/aws/latest).

## Features

- HTTP and HTTPS listener configuration
- Target group management with health checks
- Access logging to S3 (optional)
- WAF integration (optional)
- Cross-zone load balancing
- Connection draining configuration
- Standard naming and tagging conventions

## Usage

```hcl
module "alb" {
  source = "../modules/aws_alb"

  context = local.context
  name    = "alb"

  vpc_id          = module.vpc.vpc_id
  subnets         = module.vpc.public_subnet_ids
  security_groups = [module.alb_security_group.security_group_id]

  target_groups = {
    backend = {
      name             = "${var.project}-backend-tg-${var.environment}"
      backend_protocol = "HTTP"
      backend_port     = 80
      target_type      = "ip"

      health_check = {
        enabled   = true
        path      = "/health"
        protocol  = "HTTP"
        matcher   = "200"
      }
    }
  }

  listeners = {
    http = {
      port     = 80
      protocol = "HTTP"
      forward  = {
        target_group_key = "backend"
      }
    }
  }
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.0 |
| aws | >= 5.0 |

## Providers

Uses terraform-aws-modules/alb/aws version ~> 10.0

## Naming Convention

- ALB Name: `{project}-{name}-{environment}` (e.g., `myproject-alb-dev`)
- Follows the flat naming standard for AWS resource identifiers

## Outputs

- `id` - The ID of the load balancer
- `arn` - The ARN of the load balancer
- `dns_name` - The DNS name of the load balancer
- `zone_id` - The canonical hosted zone ID
- `target_groups` - Map of target groups created
- `listeners` - Map of listeners created
