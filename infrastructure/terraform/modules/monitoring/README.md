# Monitoring Module

CloudWatch alarms and SNS notifications for ECS, ALB, and RDS.

## What it does

- Creates an SNS topic for alarm notifications (when `enable_alarms = true`)
- ECS CPU and memory utilization alarms
- ALB unhealthy target count alarm
- RDS CPU utilization and free storage space alarms
- All thresholds are configurable via variables

Log groups are managed by the `ecs-fargate` module (per-container), not here.

## Usage

```hcl
module "monitoring" {
  source = "./modules/monitoring"

  context = local.context

  enable_alarms    = true
  ecs_cluster_name = module.ecs_fargate.cluster_name
  ecs_service_name = module.ecs_fargate.service_name
  alb_arn_suffix   = module.load_balancer.alb_arn_suffix
  rds_instance_id  = module.database.db_instance_id
}
```

## Inputs

See [variables.tf](./variables.tf) for the full list.

## Outputs

See [outputs.tf](./outputs.tf) for the full list.
