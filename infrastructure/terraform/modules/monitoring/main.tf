# ==============================================================================
# Monitoring Module - CloudWatch Alarms
# ==============================================================================
# Log groups are managed by the ecs-fargate module (per-container).
# This module handles alarms only.

# Optional CloudWatch Alarms (enabled for production)
resource "aws_sns_topic" "alarms" {
  count = var.enable_alarms ? 1 : 0
  name  = "${var.context.project}-${var.context.environment}-alarms"

  tags = var.context.common_tags
}

# ECS Service CPU Alarm
resource "aws_cloudwatch_metric_alarm" "ecs_cpu_high" {
  count               = var.enable_alarms ? 1 : 0
  alarm_name          = "${var.context.project}-${var.context.environment}-ecs-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = 300
  statistic           = "Average"
  threshold           = var.ecs_cpu_threshold
  alarm_description   = "This alarm monitors ECS CPU utilization"
  alarm_actions       = [aws_sns_topic.alarms[0].arn]

  dimensions = {
    ClusterName = var.ecs_cluster_name
    ServiceName = var.ecs_service_name
  }

  tags = var.context.common_tags
}

# ECS Service Memory Alarm
resource "aws_cloudwatch_metric_alarm" "ecs_memory_high" {
  count               = var.enable_alarms ? 1 : 0
  alarm_name          = "${var.context.project}-${var.context.environment}-ecs-memory-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "MemoryUtilization"
  namespace           = "AWS/ECS"
  period              = 300
  statistic           = "Average"
  threshold           = var.ecs_memory_threshold
  alarm_description   = "This alarm monitors ECS memory utilization"
  alarm_actions       = [aws_sns_topic.alarms[0].arn]

  dimensions = {
    ClusterName = var.ecs_cluster_name
    ServiceName = var.ecs_service_name
  }

  tags = var.context.common_tags
}

# ALB Target Unhealthy Alarm
resource "aws_cloudwatch_metric_alarm" "alb_unhealthy_targets" {
  count               = var.enable_alarms ? 1 : 0
  alarm_name          = "${var.context.project}-${var.context.environment}-alb-unhealthy-targets"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "UnHealthyHostCount"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Average"
  threshold           = 0
  alarm_description   = "This alarm monitors unhealthy ALB targets"
  alarm_actions       = [aws_sns_topic.alarms[0].arn]

  dimensions = {
    LoadBalancer = var.alb_arn_suffix
  }

  tags = var.context.common_tags
}

# RDS CPU Alarm
resource "aws_cloudwatch_metric_alarm" "rds_cpu_high" {
  count               = var.enable_alarms ? 1 : 0
  alarm_name          = "${var.context.project}-${var.context.environment}-rds-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = var.rds_cpu_threshold
  alarm_description   = "This alarm monitors RDS CPU utilization"
  alarm_actions       = [aws_sns_topic.alarms[0].arn]

  dimensions = {
    DBInstanceIdentifier = var.rds_instance_id
  }

  tags = var.context.common_tags
}

# RDS Storage Space Alarm
resource "aws_cloudwatch_metric_alarm" "rds_storage_low" {
  count               = var.enable_alarms ? 1 : 0
  alarm_name          = "${var.context.project}-${var.context.environment}-rds-storage-low"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 1
  metric_name         = "FreeStorageSpace"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = var.rds_storage_threshold_bytes
  alarm_description   = "This alarm monitors RDS free storage space"
  alarm_actions       = [aws_sns_topic.alarms[0].arn]

  dimensions = {
    DBInstanceIdentifier = var.rds_instance_id
  }

  tags = var.context.common_tags
}
