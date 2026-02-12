# ============================================================================
# OBSERVABILITY - CloudWatch Logs, Metrics, Alarms
# ============================================================================

# Monitoring Module (CloudWatch alarms only - log groups are managed by ecs-fargate module)
module "monitoring" {
  source = "./modules/monitoring"

  context = local.context

  enable_alarms    = local.enable_alarms
  ecs_cluster_name = module.ecs_fargate.cluster_name
  ecs_service_name = module.ecs_fargate.service_name
  alb_arn_suffix   = module.load_balancer.alb_arn_suffix
  rds_instance_id  = module.database.db_instance_id
}
