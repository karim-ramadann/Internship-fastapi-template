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



<!-- BEGIN_TF_DOCS -->
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
| [aws_cloudwatch_metric_alarm.alb_unhealthy_targets](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_cloudwatch_metric_alarm.ecs_cpu_high](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_cloudwatch_metric_alarm.ecs_memory_high](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_cloudwatch_metric_alarm.rds_cpu_high](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_cloudwatch_metric_alarm.rds_storage_low](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_sns_topic.alarms](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_context"></a> [context](#input\_context) | Context object containing project, environment, region, and common tags | <pre>object({<br/>    project     = string<br/>    environment = string<br/>    region      = string<br/>    common_tags = map(string)<br/>  })</pre> | n/a | yes |
| <a name="input_alb_arn_suffix"></a> [alb\_arn\_suffix](#input\_alb\_arn\_suffix) | ARN suffix of the ALB (required if enable\_alarms is true) | `string` | `""` | no |
| <a name="input_ecs_cluster_name"></a> [ecs\_cluster\_name](#input\_ecs\_cluster\_name) | Name of the ECS cluster (required if enable\_alarms is true) | `string` | `""` | no |
| <a name="input_ecs_cpu_threshold"></a> [ecs\_cpu\_threshold](#input\_ecs\_cpu\_threshold) | ECS CPU utilization threshold percentage | `number` | `80` | no |
| <a name="input_ecs_memory_threshold"></a> [ecs\_memory\_threshold](#input\_ecs\_memory\_threshold) | ECS memory utilization threshold percentage | `number` | `80` | no |
| <a name="input_ecs_service_name"></a> [ecs\_service\_name](#input\_ecs\_service\_name) | Name of the ECS service (required if enable\_alarms is true) | `string` | `""` | no |
| <a name="input_enable_alarms"></a> [enable\_alarms](#input\_enable\_alarms) | Enable CloudWatch alarms | `bool` | `false` | no |
| <a name="input_rds_cpu_threshold"></a> [rds\_cpu\_threshold](#input\_rds\_cpu\_threshold) | RDS CPU utilization threshold percentage | `number` | `80` | no |
| <a name="input_rds_instance_id"></a> [rds\_instance\_id](#input\_rds\_instance\_id) | ID of the RDS instance (required if enable\_alarms is true) | `string` | `""` | no |
| <a name="input_rds_storage_threshold_bytes"></a> [rds\_storage\_threshold\_bytes](#input\_rds\_storage\_threshold\_bytes) | RDS free storage space threshold in bytes (default 5GB) | `number` | `5368709120` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_sns_topic_arn"></a> [sns\_topic\_arn](#output\_sns\_topic\_arn) | ARN of the SNS topic for alarms (if enabled) |
<!-- END_TF_DOCS -->
