# ============================================================================
# OBSERVABILITY - CloudWatch Logs, Metrics, Alarms
# ============================================================================

# Monitoring Module (CloudWatch logs and alarms)
module "monitoring" {
  source = "./modules/monitoring"

  context = local.context

  log_retention_days = local.log_retention_days
  enable_alarms      = local.enable_alarms
  ecs_cluster_name   = module.ecs_cluster.cluster_name
  ecs_service_name   = aws_ecs_service.app.name
  alb_arn_suffix     = module.load_balancer.alb_arn_suffix
  rds_instance_id    = module.database.db_instance_id
}
