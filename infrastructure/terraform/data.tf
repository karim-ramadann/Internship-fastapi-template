# ============================================================================
# DATA & PERSISTENCE - RDS, ECR, S3, Storage
# ============================================================================
# Note: Data sources (aws_caller_identity, aws_availability_zones, etc.)
#       are in datasources.tf for clarity

# Database Module (RDS PostgreSQL)
module "database" {
  source = "./modules/database"

  context = local.context

  private_subnet_ids        = module.networking.private_subnet_ids
  rds_security_group_id     = module.security.rds_security_group_id
  rds_instance_class        = var.rds_instance_class
  rds_allocated_storage     = var.rds_allocated_storage
  rds_multi_az              = var.rds_multi_az
  rds_backup_retention_days = var.rds_backup_retention_days
  db_name                   = var.db_name
  db_username               = var.db_username
}

# ECR Repositories (Container Image Registry)
module "ecr" {
  source = "./modules/ecr"

  context = local.context
}

# Service Discovery Module (AWS Cloud Map)
module "service_discovery" {
  source = "./modules/service-discovery"

  context = local.context
  vpc_id  = module.networking.vpc_id
}
