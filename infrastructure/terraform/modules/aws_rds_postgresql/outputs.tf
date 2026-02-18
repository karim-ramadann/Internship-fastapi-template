output "rds_endpoint" {
  description = "RDS instance endpoint (host:port)"
  value       = module.rds.db_instance_endpoint
}

output "rds_address" {
  description = "RDS instance address (host only)"
  value       = module.rds.db_instance_address
}

output "rds_port" {
  description = "RDS instance port"
  value       = module.rds.db_instance_port
}

output "db_name" {
  description = "Name of the database"
  value       = var.db_name
}

output "db_username" {
  description = "Master username"
  value       = var.db_username
  sensitive   = true
}

output "db_password" {
  description = "Master password (managed by RDS via Secrets Manager)"
  value       = null
  sensitive   = true
}

output "db_instance_id" {
  description = "Identifier of the RDS instance"
  value       = module.rds.db_instance_identifier
}

output "db_instance_arn" {
  description = "ARN of the RDS instance"
  value       = module.rds.db_instance_arn
}

output "secrets_manager_secret_arn" {
  description = "ARN of the RDS-managed Secrets Manager secret containing database credentials"
  value       = module.rds.db_instance_master_user_secret_arn
}
