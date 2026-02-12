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

## Inputs

See [variables.tf](./variables.tf) for the full list.

## Outputs

See [outputs.tf](./outputs.tf) for the full list.

## Upstream Module

- [terraform-aws-modules/ecs/aws](https://registry.terraform.io/modules/terraform-aws-modules/ecs/aws/latest)
