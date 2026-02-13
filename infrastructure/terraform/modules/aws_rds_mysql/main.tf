/**
 * # RDS MySQL Module
 *
 * Thin wrapper around [terraform-aws-modules/rds/aws](https://registry.terraform.io/modules/terraform-aws-modules/rds/aws/latest).
 *
 * Standards enforced:
 * - Naming convention: `{project}-mysql-{environment}`
 * - Random password generation with Secrets Manager storage
 * - Automatic subnet group creation
 * - Environment-based defaults (deletion protection, monitoring, backups)
 * - Storage encryption enabled by default
 */

resource "random_password" "db_password" {
  length           = 32
  special          = true
  override_special = "!#$%&*()-_=+[]{}:?"
}

resource "aws_db_subnet_group" "main" {
  name        = "${var.context.project}-mysql-subnet-group-${var.context.environment}"
  description = "DB subnet group for ${var.context.project} ${var.context.environment}"
  subnet_ids  = var.private_subnet_ids

  tags = merge(
    var.context.common_tags,
    { Name = "${var.context.project}-mysql-subnet-group-${var.context.environment}" }
  )
}

module "rds" {
  source  = "terraform-aws-modules/rds/aws"
  version = "~> 7.0"

  identifier = "${var.context.project}-mysql-${var.context.environment}"

  engine               = "mysql"
  engine_version       = var.engine_version
  family               = "mysql${var.engine_version}"
  major_engine_version = var.engine_version
  instance_class       = var.instance_class

  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.allocated_storage * 2
  storage_type          = var.storage_type
  storage_encrypted     = true

  db_name             = var.db_name
  username            = var.db_username
  port                = 3306
  password_wo         = random_password.db_password.result
  password_wo_version = 1

  multi_az               = var.multi_az
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [var.security_group_id]
  publicly_accessible    = false

  backup_retention_period          = var.backup_retention_days
  backup_window                    = "03:00-04:00"
  maintenance_window               = "mon:04:00-mon:05:00"
  skip_final_snapshot              = var.context.environment != "production"
  final_snapshot_identifier_prefix = "${var.context.project}-mysql-final-${var.context.environment}"

  deletion_protection   = var.context.environment == "production"
  copy_tags_to_snapshot = true

  enabled_cloudwatch_logs_exports = ["general", "error", "slowquery"]

  performance_insights_enabled          = var.context.environment == "production"
  performance_insights_retention_period = var.context.environment == "production" ? 7 : null

  monitoring_interval    = var.context.environment == "production" ? 60 : 0
  monitoring_role_name   = var.context.environment == "production" ? "${var.context.project}-mysql-monitoring-${var.context.environment}" : null
  create_monitoring_role = var.context.environment == "production"

  tags = merge(
    var.context.common_tags,
    { Name = "${var.context.project}-mysql-${var.context.environment}" }
  )
}

resource "aws_secretsmanager_secret" "db_credentials" {
  name        = "${var.context.environment}/${var.context.project}/mysql/credentials"
  description = "MySQL credentials for ${var.context.project} ${var.context.environment}"
  tags        = var.context.common_tags
}

resource "aws_secretsmanager_secret_version" "db_credentials" {
  secret_id = aws_secretsmanager_secret.db_credentials.id
  secret_string = jsonencode({
    username = var.db_username
    password = random_password.db_password.result
    engine   = "mysql"
    host     = module.rds.db_instance_address
    port     = module.rds.db_instance_port
    dbname   = var.db_name
  })
}
