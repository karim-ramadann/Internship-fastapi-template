# Networking Module
module "networking" {
  source = "./modules/networking"

  context = local.context

  vpc_cidr             = var.vpc_cidr
  availability_zones   = slice(data.aws_availability_zones.available.names, 0, 2)
  public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnet_cidrs = ["10.0.10.0/24", "10.0.11.0/24"]
}

# Security Module
module "security" {
  source = "./modules/security"

  context = local.context
  vpc_id  = module.networking.vpc_id
}

# Route53 Module (must come before ACM for DNS validation)
module "route53" {
  source = "./modules/route53"

  context = local.context

  domain             = var.domain
  create_hosted_zone = var.create_hosted_zone
  
  # ALB DNS will be provided after load balancer is created
  alb_dns_name = module.load_balancer.alb_dns_name
  alb_zone_id  = module.load_balancer.alb_zone_id
}

# ACM Certificate Module (with automatic DNS validation)
module "acm" {
  source = "./modules/acm"

  context = local.context

  domain           = var.domain
  route53_zone_id  = module.route53.zone_id
}

# Database Module
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

# ECR Module
module "ecr" {
  source = "./modules/ecr"

  context = local.context
}

# Service Discovery Module
module "service_discovery" {
  source = "./modules/service-discovery"

  context = local.context
  vpc_id  = module.networking.vpc_id
}

# Monitoring Module
module "monitoring" {
  source = "./modules/monitoring"

  context = local.context

  log_retention_days = local.log_retention_days
  enable_alarms      = local.enable_alarms
  ecs_cluster_name   = module.compute.ecs_cluster_name
  ecs_service_name   = module.compute.ecs_service_name
  alb_arn_suffix     = module.load_balancer.alb_arn_suffix
  rds_instance_id    = module.database.db_instance_id
}

# Load Balancer Module
module "load_balancer" {
  source = "./modules/load-balancer"

  context = local.context

  vpc_id                 = module.networking.vpc_id
  public_subnet_ids      = module.networking.public_subnet_ids
  alb_security_group_id  = module.security.alb_security_group_id
  domain                 = var.domain
  certificate_arn        = module.acm.certificate_arn
}

# Compute Module (ECS)
module "compute" {
  source = "./modules/compute"

  context = local.context

  private_subnet_ids           = module.networking.private_subnet_ids
  ecs_security_group_id        = module.security.ecs_security_group_id
  ecs_instance_profile_name    = module.security.ecs_instance_profile_name
  ecs_task_execution_role_arn  = module.security.ecs_task_execution_role_arn
  ecs_task_role_arn            = module.security.ecs_task_role_arn
  
  backend_repository_url       = module.ecr.backend_repository_url
  frontend_repository_url      = module.ecr.frontend_repository_url
  backend_image_tag            = var.backend_image_tag
  frontend_image_tag           = var.frontend_image_tag
  
  rds_address                  = module.database.rds_address
  
  backend_target_group_arn     = module.load_balancer.backend_target_group_arn
  frontend_target_group_arn    = module.load_balancer.frontend_target_group_arn
  adminer_target_group_arn     = module.load_balancer.adminer_target_group_arn
  
  backend_log_group_name       = module.monitoring.backend_log_group_name
  frontend_log_group_name      = module.monitoring.frontend_log_group_name
  adminer_log_group_name       = module.monitoring.adminer_log_group_name
  prestart_log_group_name      = module.monitoring.prestart_log_group_name
  
  instance_type                = var.ec2_instance_type
  desired_count                = var.ecs_desired_count
  
  service_discovery_registry_arn = module.service_discovery.backend_service_arn

  # Environment variables for containers
  common_environment_variables = [
    { name = "DOMAIN", value = var.domain },
    { name = "FRONTEND_HOST", value = var.frontend_host },
    { name = "ENVIRONMENT", value = var.environment },
    { name = "PROJECT_NAME", value = var.project },
    { name = "BACKEND_CORS_ORIGINS", value = var.backend_cors_origins },
    { name = "FIRST_SUPERUSER", value = var.first_superuser },
    { name = "EMAILS_FROM_EMAIL", value = var.emails_from_email },
    { name = "SMTP_TLS", value = tostring(var.smtp_tls) },
    { name = "SMTP_SSL", value = tostring(var.smtp_ssl) },
    { name = "SMTP_PORT", value = tostring(var.smtp_port) },
    { name = "POSTGRES_PORT", value = "5432" },
    { name = "POSTGRES_DB", value = var.db_name },
    { name = "POSTGRES_USER", value = var.db_username },
  ]

  # Secrets from SSM Parameter Store
  common_secrets = concat(
    [
      { name = "SECRET_KEY", valueFrom = aws_ssm_parameter.secret_key.arn },
      { name = "FIRST_SUPERUSER_PASSWORD", valueFrom = aws_ssm_parameter.first_superuser_password.arn },
      { name = "POSTGRES_PASSWORD", valueFrom = aws_ssm_parameter.postgres_password.arn },
    ],
    var.smtp_host != "" ? [{ name = "SMTP_HOST", valueFrom = aws_ssm_parameter.smtp_host[0].arn }] : [],
    var.smtp_user != "" ? [{ name = "SMTP_USER", valueFrom = aws_ssm_parameter.smtp_user[0].arn }] : [],
    var.smtp_password != "" ? [{ name = "SMTP_PASSWORD", valueFrom = aws_ssm_parameter.smtp_password[0].arn }] : [],
    var.sentry_dsn != "" ? [{ name = "SENTRY_DSN", valueFrom = aws_ssm_parameter.sentry_dsn[0].arn }] : []
  )

  depends_on = [
    module.load_balancer,
    module.database
  ]
}
