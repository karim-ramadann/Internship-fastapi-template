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

<!-- BEGIN_TF_DOCS -->
# Application Load Balancer Module

Thin wrapper around [terraform-aws-modules/alb/aws](https://registry.terraform.io/modules/terraform-aws-modules/alb/aws/latest).

Manages the ALB, target groups, HTTPS/HTTP listeners, and host-based routing rules.
Business logic (which hosts route where) is driven by variables, not hardcoded.

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
| <a name="module_alb"></a> [alb](#module\_alb) | terraform-aws-modules/alb/aws | ~> 9.0 |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_certificate_arn"></a> [certificate\_arn](#input\_certificate\_arn) | ARN of the ACM certificate for HTTPS listener | `string` | n/a | yes |
| <a name="input_context"></a> [context](#input\_context) | Context object containing project, environment, region, and common tags | <pre>object({<br/>    project     = string<br/>    environment = string<br/>    region      = string<br/>    common_tags = map(string)<br/>  })</pre> | n/a | yes |
| <a name="input_security_groups"></a> [security\_groups](#input\_security\_groups) | List of security group IDs to assign to the load balancer | `list(string)` | n/a | yes |
| <a name="input_subnets"></a> [subnets](#input\_subnets) | List of subnet IDs for the load balancer | `list(string)` | n/a | yes |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | ID of the VPC where the load balancer will be created | `string` | n/a | yes |
| <a name="input_access_logs"></a> [access\_logs](#input\_access\_logs) | Map containing access logging configuration | `map(string)` | `{}` | no |
| <a name="input_enable_cross_zone_load_balancing"></a> [enable\_cross\_zone\_load\_balancing](#input\_enable\_cross\_zone\_load\_balancing) | Enable cross-zone load balancing | `bool` | `true` | no |
| <a name="input_enable_deletion_protection"></a> [enable\_deletion\_protection](#input\_enable\_deletion\_protection) | Enable deletion protection on the load balancer | `bool` | `false` | no |
| <a name="input_enable_http2"></a> [enable\_http2](#input\_enable\_http2) | Enable HTTP/2 support | `bool` | `true` | no |
| <a name="input_host_rules"></a> [host\_rules](#input\_host\_rules) | Map of host-based routing rules for the HTTPS listener.<br/>Each key is a logical name; target\_group\_key must match a key in var.target\_groups.<br/>Example:<br/>host\_rules = {<br/>  backend  = { host = "api.example.com",       target\_group\_key = "backend",  priority = 100 }<br/>  frontend = { host = "dashboard.example.com",  target\_group\_key = "frontend", priority = 200 }<br/>} | <pre>map(object({<br/>    host             = string<br/>    target_group_key = string<br/>    priority         = number<br/>  }))</pre> | `{}` | no |
| <a name="input_internal"></a> [internal](#input\_internal) | Whether the load balancer is internal or internet-facing | `bool` | `false` | no |
| <a name="input_load_balancer_type"></a> [load\_balancer\_type](#input\_load\_balancer\_type) | Type of load balancer to create (application, network, or gateway) | `string` | `"application"` | no |
| <a name="input_target_groups"></a> [target\_groups](#input\_target\_groups) | Map of target group definitions. Each key becomes part of the TG name.<br/>Example:<br/>target\_groups = {<br/>  backend = {<br/>    port              = 8000<br/>    protocol          = "HTTP"<br/>    target\_type       = "ip"<br/>    health\_check\_path = "/api/v1/utils/health-check/"<br/>  }<br/>} | <pre>map(object({<br/>    port                = number<br/>    protocol            = optional(string, "HTTP")<br/>    target_type         = optional(string, "ip")<br/>    health_check_path   = optional(string, "/")<br/>    deregistration_delay = optional(number, 30)<br/>  }))</pre> | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_alb_arn"></a> [alb\_arn](#output\_alb\_arn) | ARN of the Application Load Balancer |
| <a name="output_alb_arn_suffix"></a> [alb\_arn\_suffix](#output\_alb\_arn\_suffix) | ARN suffix of the Application Load Balancer for use with CloudWatch metrics |
| <a name="output_alb_dns_name"></a> [alb\_dns\_name](#output\_alb\_dns\_name) | DNS name of the Application Load Balancer |
| <a name="output_alb_id"></a> [alb\_id](#output\_alb\_id) | ID of the Application Load Balancer |
| <a name="output_alb_zone_id"></a> [alb\_zone\_id](#output\_alb\_zone\_id) | Zone ID of the Application Load Balancer for Route53 alias records |
| <a name="output_security_group_ids"></a> [security\_group\_ids](#output\_security\_group\_ids) | Security group IDs attached to the load balancer |
| <a name="output_target_group_arns"></a> [target\_group\_arns](#output\_target\_group\_arns) | Map of target group key to ARN |
<!-- END_TF_DOCS -->