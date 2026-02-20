# DB Subnet Group
resource "aws_db_subnet_group" "main" {
  # Naming standard: project-resource-name-env (flat)
  name        = "${var.context.project}-db-subnet-group-${var.context.environment}"
  description = "DB subnet group for ${var.context.project} ${var.context.environment}"
  subnet_ids  = var.private_subnet_ids

  tags = merge(
    var.context.common_tags,
    {
      Name = "${var.context.project}-db-subnet-group-${var.context.environment}"
    }
  )
}

# RDS PostgreSQL Instance using terraform-aws-modules/rds
module "rds" {
  source  = "terraform-aws-modules/rds/aws"
  version = "~> 7.0"

  # Naming standard: project-resource-name-env (flat)
  identifier = "${var.context.project}-db-${var.context.environment}"

  engine               = "postgres"
  engine_version       = var.rds_engine_version
  family               = "postgres${split(".", var.rds_engine_version)[0]}" # e.g., postgres18
  major_engine_version = split(".", var.rds_engine_version)[0]              # e.g., 18
  instance_class       = var.rds_instance_class

  # Storage
  allocated_storage     = var.rds_allocated_storage
  max_allocated_storage = var.rds_allocated_storage * 2 # Auto-scaling up to 2x
  storage_type          = var.rds_storage_type
  storage_encrypted     = true

  # Database
  db_name             = var.db_name
  username            = var.db_username
  port                = 5432
  # Let RDS manage the master password via Secrets Manager
  manage_master_user_password = true

  # Network
  multi_az               = var.rds_multi_az
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [var.rds_security_group_id]
  publicly_accessible    = false

  # Backup
  backup_retention_period = var.rds_backup_retention_days
  backup_window           = "03:00-04:00"
  maintenance_window      = "mon:04:00-mon:05:00"
  skip_final_snapshot     = var.context.environment != "production"
  # Naming standard: project-resource-name-env (flat)
  final_snapshot_identifier_prefix = "${var.context.project}-db-final-snapshot-${var.context.environment}"

  # IAM Database Authentication
  iam_database_authentication_enabled = true

  # Protection
  deletion_protection   = var.context.environment == "production"
  copy_tags_to_snapshot = true

  # CloudWatch Logs
  enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]

  # Performance Insights
  performance_insights_enabled          = var.context.environment == "production"
  performance_insights_retention_period = var.context.environment == "production" ? 7 : null

  # Monitoring
  monitoring_interval = var.context.environment == "production" ? 60 : 0
  # Naming standard: project-resource-name-env (flat)
  monitoring_role_name   = var.context.environment == "production" ? "${var.context.project}-rds-monitoring-role-${var.context.environment}" : null
  create_monitoring_role = var.context.environment == "production"

  tags = merge(
    var.context.common_tags,
    {
      Name = "${var.context.project}-db-${var.context.environment}"
    }
  )
}
