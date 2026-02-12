# ECS Fargate Module

Thin wrapper around [`terraform-aws-modules/ecs/aws`](https://registry.terraform.io/modules/terraform-aws-modules/ecs/aws/latest) for Fargate workloads.

## What it does

- Creates an ECS cluster with Fargate capacity providers (FARGATE + FARGATE_SPOT)
- Defines a single ECS service with a multi-container task definition
- Manages per-container CloudWatch log groups automatically
- Creates task execution and task IAM roles with SSM/Secrets Manager access
- Creates a security group for the service
- Supports optional sidecar containers (CW agent, X-Ray, Datadog, etc.)
- Supports Application Auto Scaling with target tracking policies
- Supports deployment circuit breaker with automatic rollback

## Cross-Repo Image Tag Updates

This module is designed for a workflow where the backend repo pushes images to ECR and then opens a PR against this IaC repo to update the image tag:

1. Backend CI builds and pushes `backend:staging-abc1234` to ECR
2. Backend CI opens a PR in the IaC repo updating `backend_image_tag` in tfvars
3. IaC CI runs `terraform plan` on the PR
4. On merge, `terraform apply` deploys the new image

Set `ignore_task_definition_changes = true` if you prefer CI/CD to update the task definition directly via `aws ecs update-service`.

## Usage

```hcl
module "ecs_fargate" {
  source = "./modules/ecs-fargate"

  context = local.context

  # Networking
  vpc_id     = module.networking.vpc_id
  subnet_ids = module.networking.private_subnet_ids

  # Task sizing
  task_cpu    = 1024
  task_memory = 2048

  # Application containers
  containers = {
    prestart = {
      image     = "${module.ecr.backend_repository_url}:${var.backend_image_tag}"
      essential = false
      command   = ["bash", "scripts/prestart.sh"]
      environment = local.common_environment_variables
      secrets     = local.common_secrets
    }
    backend = {
      image = "${module.ecr.backend_repository_url}:${var.backend_image_tag}"
      port  = 8000
      health_check = {
        command = ["CMD-SHELL", "curl -f http://localhost:8000/api/v1/utils/health-check/ || exit 1"]
      }
      environment = local.common_environment_variables
      secrets     = local.common_secrets
      depends_on  = [{ containerName = "prestart", condition = "SUCCESS" }]
    }
    frontend = {
      image = "${module.ecr.frontend_repository_url}:${var.frontend_image_tag}"
      port  = 80
    }
  }

  # Optional sidecar for enhanced logging
  sidecar_containers = {
    cwagent = {
      image     = "public.ecr.aws/cloudwatch-agent/cloudwatch-agent:latest"
      essential = false
      environment = [
        { name = "CW_CONFIG_CONTENT", value = jsonencode({ ... }) }
      ]
    }
  }

  # Load balancer
  load_balancers = {
    backend  = { container_name = "backend",  container_port = 8000, target_group_arn = aws_lb_target_group.backend.arn }
    frontend = { container_name = "frontend", container_port = 80,   target_group_arn = aws_lb_target_group.frontend.arn }
  }

  # Security group rules
  security_group_rules = {
    backend_from_alb = {
      type      = "ingress"
      from_port = 8000
      to_port   = 8000
      protocol  = "tcp"
      source_security_group_id = module.security.alb_security_group_id
    }
  }

  # Autoscaling
  enable_autoscaling       = true
  autoscaling_min_capacity = 1
  autoscaling_max_capacity = 10
  autoscaling_policies = {
    cpu = {
      policy_type = "TargetTrackingScaling"
      target_tracking_scaling_policy_configuration = {
        predefined_metric_specification = {
          predefined_metric_type = "ECSServiceAverageCPUUtilization"
        }
        target_value = 70
      }
    }
  }
}
```

## Upstream Module

- [terraform-aws-modules/ecs/aws](https://registry.terraform.io/modules/terraform-aws-modules/ecs/aws/latest)

<!-- BEGIN_TF_DOCS -->
## Requirements

No requirements.

## Providers

No providers.

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_cluster"></a> [cluster](#module\_cluster) | terraform-aws-modules/ecs/aws//modules/cluster | ~> 5.0 |
| <a name="module_service"></a> [service](#module\_service) | terraform-aws-modules/ecs/aws//modules/service | ~> 5.0 |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_context"></a> [context](#input\_context) | Context object containing project, environment, region, and common tags | <pre>object({<br/>    project     = string<br/>    environment = string<br/>    region      = string<br/>    common_tags = map(string)<br/>  })</pre> | n/a | yes |
| <a name="input_subnet_ids"></a> [subnet\_ids](#input\_subnet\_ids) | Subnet IDs where Fargate tasks will run | `list(string)` | n/a | yes |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | VPC ID for the ECS service security group | `string` | n/a | yes |
| <a name="input_assign_public_ip"></a> [assign\_public\_ip](#input\_assign\_public\_ip) | Assign a public IP to the Fargate task ENI | `bool` | `false` | no |
| <a name="input_autoscaling_max_capacity"></a> [autoscaling\_max\_capacity](#input\_autoscaling\_max\_capacity) | Maximum number of tasks | `number` | `10` | no |
| <a name="input_autoscaling_min_capacity"></a> [autoscaling\_min\_capacity](#input\_autoscaling\_min\_capacity) | Minimum number of tasks | `number` | `1` | no |
| <a name="input_autoscaling_policies"></a> [autoscaling\_policies](#input\_autoscaling\_policies) | Map of autoscaling policy configurations. Supports target tracking.<br/>Example:<br/>autoscaling\_policies = {<br/>  cpu = {<br/>    policy\_type = "TargetTrackingScaling"<br/>    target\_tracking\_scaling\_policy\_configuration = {<br/>      predefined\_metric\_specification = {<br/>        predefined\_metric\_type = "ECSServiceAverageCPUUtilization"<br/>      }<br/>      target\_value       = 70<br/>      scale\_in\_cooldown  = 300<br/>      scale\_out\_cooldown = 60<br/>    }<br/>  }<br/>} | `any` | `{}` | no |
| <a name="input_cloudwatch_log_group_retention_in_days"></a> [cloudwatch\_log\_group\_retention\_in\_days](#input\_cloudwatch\_log\_group\_retention\_in\_days) | Number of days to retain cluster-level log events | `number` | `30` | no |
| <a name="input_container_definitions"></a> [container\_definitions](#input\_container\_definitions) | Map of container definitions passed directly to the community module.<br/>Each key is the container name. Values use the community module's native<br/>attribute names (image, essential, command, port\_mappings, dependencies,<br/>environment, secrets, health\_check, etc.).<br/><br/>Computed values (ECR URLs, SSM ARNs) are safe here because the map keys<br/>are static strings — only values can be unknown at plan time.<br/><br/>Per-container CloudWatch log groups are configured via container\_definition\_defaults.<br/>Override per container by setting cloudwatch\_log\_group\_name in the value.<br/><br/>Example:<br/>container\_definitions = {<br/>  backend = {<br/>    image     = "${module.ecr.backend\_repository\_url}:latest"<br/>    essential = true<br/>    port\_mappings = [{<br/>      containerPort = 8000<br/>      protocol      = "tcp"<br/>      name          = "backend"<br/>    }]<br/>    environment = [{ name = "ENV", value = "staging" }]<br/>    secrets     = [{ name = "SECRET\_KEY", valueFrom = "arn:aws:ssm:..." }]<br/>    cloudwatch\_log\_group\_name = "/ecs/myapp/backend"<br/>  }<br/>} | `any` | `{}` | no |
| <a name="input_create_cloudwatch_log_group"></a> [create\_cloudwatch\_log\_group](#input\_create\_cloudwatch\_log\_group) | Whether the ECS module creates a CloudWatch log group for the cluster | `bool` | `true` | no |
| <a name="input_deployment_maximum_percent"></a> [deployment\_maximum\_percent](#input\_deployment\_maximum\_percent) | Upper limit (% of desired\_count) of tasks during deployment | `number` | `200` | no |
| <a name="input_deployment_minimum_healthy_percent"></a> [deployment\_minimum\_healthy\_percent](#input\_deployment\_minimum\_healthy\_percent) | Lower limit (% of desired\_count) of tasks that must remain healthy during deployment | `number` | `100` | no |
| <a name="input_desired_count"></a> [desired\_count](#input\_desired\_count) | Desired number of running tasks | `number` | `1` | no |
| <a name="input_enable_autoscaling"></a> [enable\_autoscaling](#input\_enable\_autoscaling) | Enable Application Auto Scaling for the service | `bool` | `false` | no |
| <a name="input_enable_container_insights"></a> [enable\_container\_insights](#input\_enable\_container\_insights) | Enable CloudWatch Container Insights for the cluster | `bool` | `true` | no |
| <a name="input_enable_deployment_circuit_breaker"></a> [enable\_deployment\_circuit\_breaker](#input\_enable\_deployment\_circuit\_breaker) | Enable ECS deployment circuit breaker with rollback | `bool` | `true` | no |
| <a name="input_force_new_deployment"></a> [force\_new\_deployment](#input\_force\_new\_deployment) | Force a new deployment of the service (useful for image tag updates) | `bool` | `false` | no |
| <a name="input_health_check_grace_period_seconds"></a> [health\_check\_grace\_period\_seconds](#input\_health\_check\_grace\_period\_seconds) | Seconds to wait before ECS starts checking ALB health for new tasks | `number` | `180` | no |
| <a name="input_ignore_task_definition_changes"></a> [ignore\_task\_definition\_changes](#input\_ignore\_task\_definition\_changes) | Ignore changes to the task definition (useful when CI/CD updates it externally) | `bool` | `false` | no |
| <a name="input_load_balancers"></a> [load\_balancers](#input\_load\_balancers) | Map of load balancer attachments for the service.<br/>Example:<br/>load\_balancers = {<br/>  backend = {<br/>    container\_name   = "backend"<br/>    container\_port   = 8000<br/>    target\_group\_arn = aws\_lb\_target\_group.backend.arn<br/>  }<br/>} | <pre>map(object({<br/>    container_name   = string<br/>    container_port   = number<br/>    target_group_arn = string<br/>  }))</pre> | `{}` | no |
| <a name="input_log_retention_days"></a> [log\_retention\_days](#input\_log\_retention\_days) | CloudWatch log retention in days for container log groups | `number` | `14` | no |
| <a name="input_security_group_rules"></a> [security\_group\_rules](#input\_security\_group\_rules) | Map of ingress/egress rules for the ECS service security group.<br/>Example:<br/>security\_group\_rules = {<br/>  backend\_ingress = {<br/>    type                     = "ingress"<br/>    from\_port                = 8000<br/>    to\_port                  = 8000<br/>    protocol                 = "tcp"<br/>    source\_security\_group\_id = module.security.alb\_security\_group\_id<br/>  }<br/>} | <pre>map(object({<br/>    type                     = string<br/>    from_port                = number<br/>    to_port                  = number<br/>    protocol                 = string<br/>    cidr_ipv4                = optional(string, null)<br/>    source_security_group_id = optional(string, null)<br/>    description              = optional(string, "")<br/>  }))</pre> | `{}` | no |
| <a name="input_service_registries"></a> [service\_registries](#input\_service\_registries) | Service discovery registry configuration | <pre>object({<br/>    registry_arn   = string<br/>    container_name = optional(string, null)<br/>    container_port = optional(number, null)<br/>  })</pre> | `null` | no |
| <a name="input_task_cpu"></a> [task\_cpu](#input\_task\_cpu) | CPU units for the Fargate task (256, 512, 1024, 2048, 4096) | `number` | `1024` | no |
| <a name="input_task_exec_secret_arns"></a> [task\_exec\_secret\_arns](#input\_task\_exec\_secret\_arns) | List of Secrets Manager ARNs the task execution role can read | `list(string)` | `[]` | no |
| <a name="input_task_exec_ssm_param_arns"></a> [task\_exec\_ssm\_param\_arns](#input\_task\_exec\_ssm\_param\_arns) | List of SSM Parameter Store ARNs the task execution role can read (for secrets injection) | `list(string)` | `[]` | no |
| <a name="input_task_memory"></a> [task\_memory](#input\_task\_memory) | Memory (MiB) for the Fargate task | `number` | `2048` | no |
| <a name="input_tasks_iam_role_statements"></a> [tasks\_iam\_role\_statements](#input\_tasks\_iam\_role\_statements) | Additional IAM policy statements for the task role (application-level permissions) | <pre>list(object({<br/>    sid       = optional(string)<br/>    actions   = list(string)<br/>    effect    = optional(string, "Allow")<br/>    resources = list(string)<br/>    condition = optional(list(object({<br/>      test     = string<br/>      values   = list(string)<br/>      variable = string<br/>    })), [])<br/>  }))</pre> | `[]` | no |
| <a name="input_wait_for_steady_state"></a> [wait\_for\_steady\_state](#input\_wait\_for\_steady\_state) | Wait for the service to reach a steady state after deployment | `bool` | `false` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_autoscaling_policies"></a> [autoscaling\_policies](#output\_autoscaling\_policies) | Map of autoscaling policies |
| <a name="output_cluster_arn"></a> [cluster\_arn](#output\_cluster\_arn) | ARN of the ECS cluster |
| <a name="output_cluster_id"></a> [cluster\_id](#output\_cluster\_id) | ID of the ECS cluster |
| <a name="output_cluster_name"></a> [cluster\_name](#output\_cluster\_name) | Name of the ECS cluster |
| <a name="output_container_log_groups"></a> [container\_log\_groups](#output\_container\_log\_groups) | Map of container name to CloudWatch log group name |
| <a name="output_security_group_id"></a> [security\_group\_id](#output\_security\_group\_id) | ID of the ECS service security group |
| <a name="output_service_id"></a> [service\_id](#output\_service\_id) | ID of the ECS service |
| <a name="output_service_name"></a> [service\_name](#output\_service\_name) | Name of the ECS service |
| <a name="output_task_definition_arn"></a> [task\_definition\_arn](#output\_task\_definition\_arn) | Full ARN of the task definition (includes revision) |
| <a name="output_task_exec_iam_role_arn"></a> [task\_exec\_iam\_role\_arn](#output\_task\_exec\_iam\_role\_arn) | ARN of the task execution IAM role |
| <a name="output_tasks_iam_role_arn"></a> [tasks\_iam\_role\_arn](#output\_tasks\_iam\_role\_arn) | ARN of the task IAM role (application permissions) |
<!-- END_TF_DOCS -->
