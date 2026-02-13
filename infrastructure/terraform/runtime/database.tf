# ============================================================================
# RDS PostgreSQL Database
# ============================================================================

module "database" {
  source = "../modules/aws_rds_postgresql"

  context = local.context

  # Network Configuration
  private_subnet_ids    = module.vpc.private_subnet_ids
  rds_security_group_id = module.rds_security_group.security_group_id

  # Database Configuration
  db_name     = var.db_name
  db_username = var.db_username

  # Instance Configuration
  rds_instance_class        = var.rds_instance_class
  rds_allocated_storage     = var.rds_allocated_storage
  rds_multi_az              = var.rds_multi_az
  rds_backup_retention_days = var.rds_backup_retention_days
}
