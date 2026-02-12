# Application Load Balancer Module

Thin wrapper around [terraform-aws-modules/alb/aws](https://registry.terraform.io/modules/terraform-aws-modules/alb/aws/latest).

Manages the full ALB stack: the load balancer itself, target groups, HTTP→HTTPS redirect,
HTTPS listener, and host-based routing rules.

## What it provides

- ALB with HTTP/2, cross-zone LB, configurable deletion protection
- Target groups with health checks (driven by `target_groups` variable)
- HTTP listener that redirects to HTTPS
- HTTPS listener with a default 404 fixed response
- Host-based routing rules (driven by `host_rules` variable)
- Naming convention: `{project}-{environment}-alb`, `{project}-{environment}-{key}-tg`

## Usage

```hcl
module "load_balancer" {
  source = "./modules/load-balancer"

  context = local.context

  vpc_id          = module.networking.vpc_id
  subnets         = module.networking.public_subnet_ids
  security_groups = [module.security.alb_security_group_id]
  certificate_arn = module.acm.certificate_arn

  enable_deletion_protection = var.environment == "production"

  target_groups = {
    backend  = { port = 8000, health_check_path = "/api/v1/utils/health-check/" }
    frontend = { port = 80,   health_check_path = "/" }
  }

  host_rules = {
    backend  = { host = "api.example.com",       target_group_key = "backend",  priority = 100 }
    frontend = { host = "dashboard.example.com",  target_group_key = "frontend", priority = 200 }
  }
}
```

## Outputs

Target group ARNs are exposed as `target_group_arns["backend"]`, `target_group_arns["frontend"]`, etc.
Pass these into your ECS service's `load_balancer` blocks.

## Upstream Module

- [terraform-aws-modules/alb/aws](https://registry.terraform.io/modules/terraform-aws-modules/alb/aws/latest)
