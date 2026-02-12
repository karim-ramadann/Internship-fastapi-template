# ============================================================================
# COMPUTE - ECS Fargate Cluster, Services, Tasks
# ============================================================================

# Common environment variables for all backend containers
locals {
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
    { name = "POSTGRES_SERVER", value = module.database.rds_address }
  ]

  # Secrets from SSM Parameter Store / Secrets Manager
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
}

# ============================================================================
# ECS Fargate Module
# ============================================================================

module "ecs_fargate" {
  source = "./modules/ecs-fargate"

  context = local.context

  # Networking
  vpc_id     = module.networking.vpc_id
  subnet_ids = module.networking.private_subnet_ids

  # Task sizing
  task_cpu    = var.task_cpu
  task_memory = var.task_memory

  # Cluster settings
  enable_container_insights              = var.environment == "production"
  cloudwatch_log_group_retention_in_days = local.log_retention_days
  log_retention_days                     = local.log_retention_days

  # Service settings
  desired_count                      = var.ecs_desired_count
  deployment_minimum_healthy_percent = var.environment == "production" ? 100 : 50
  deployment_maximum_percent         = 200
  enable_deployment_circuit_breaker  = true

  # ---------------------------------------------------------------------------
  # Container Definitions (community module native format)
  # ---------------------------------------------------------------------------
  container_definitions = {
    # Prestart - runs database migrations before backend starts
    prestart = {
      image     = "${module.ecr.backend_repository_url}:${var.backend_image_tag}"
      essential = false
      command   = ["bash", "scripts/prestart.sh"]

      environment = local.common_environment_variables
      secrets     = local.common_secrets

      cloudwatch_log_group_name = "${var.environment}/ecs/${var.project}/prestart"
    }

    # Backend API
    backend = {
      image = "${module.ecr.backend_repository_url}:${var.backend_image_tag}"

      port_mappings = [{
        containerPort = 8000
        protocol      = "tcp"
        name          = "backend"
      }]

      health_check = {
        command     = ["CMD-SHELL", "curl -f http://localhost:8000/api/v1/utils/health-check/ || exit 1"]
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 60
      }

      environment = local.common_environment_variables
      secrets     = local.common_secrets

      dependencies = [
        { containerName = "prestart", condition = "SUCCESS" }
      ]

      cloudwatch_log_group_name = "${var.environment}/ecs/${var.project}/backend"
    }

    # Frontend dashboard (nginx serving the SPA)
    frontend = {
      image = "${module.ecr.frontend_repository_url}:${var.frontend_image_tag}"

      port_mappings = [{
        containerPort = 80
        protocol      = "tcp"
        name          = "frontend"
      }]

      cloudwatch_log_group_name = "${var.environment}/ecs/${var.project}/frontend"
    }

    # Adminer database management UI
    adminer = {
      image     = "adminer:latest"
      essential = false

      port_mappings = [{
        containerPort = 8080
        protocol      = "tcp"
        name          = "adminer"
      }]

      environment = [
        { name = "ADMINER_DESIGN", value = "pepa-linha-dark" }
      ]

      cloudwatch_log_group_name = "${var.environment}/ecs/${var.project}/adminer"
    }
  }

  # ---------------------------------------------------------------------------
  # Task Execution IAM - SSM/Secrets ARNs for pulling secrets into containers
  # ---------------------------------------------------------------------------
  task_exec_ssm_param_arns = [
    "arn:aws:ssm:${var.aws_region}:*:parameter/${var.environment}/${var.project}/*"
  ]
  task_exec_secret_arns = [
    "arn:aws:secretsmanager:${var.aws_region}:*:secret:${var.environment}/${var.project}/*"
  ]

  # ---------------------------------------------------------------------------
  # Load Balancer Attachments (TG ARNs from the load-balancer module)
  # ---------------------------------------------------------------------------
  load_balancers = {
    backend = {
      container_name   = "backend"
      container_port   = 8000
      target_group_arn = module.load_balancer.target_group_arns["backend"]
    }
    frontend = {
      container_name   = "frontend"
      container_port   = 80
      target_group_arn = module.load_balancer.target_group_arns["frontend"]
    }
    adminer = {
      container_name   = "adminer"
      container_port   = 8080
      target_group_arn = module.load_balancer.target_group_arns["adminer"]
    }
  }

  health_check_grace_period_seconds = 180

  # ---------------------------------------------------------------------------
  # Security Group Rules
  # ---------------------------------------------------------------------------
  security_group_rules = {
    backend_from_alb = {
      type                     = "ingress"
      from_port                = 8000
      to_port                  = 8000
      protocol                 = "tcp"
      source_security_group_id = module.security.alb_security_group_id
      description              = "Backend from ALB"
    }
    frontend_from_alb = {
      type                     = "ingress"
      from_port                = 80
      to_port                  = 80
      protocol                 = "tcp"
      source_security_group_id = module.security.alb_security_group_id
      description              = "Frontend from ALB"
    }
    adminer_from_alb = {
      type                     = "ingress"
      from_port                = 8080
      to_port                  = 8080
      protocol                 = "tcp"
      source_security_group_id = module.security.alb_security_group_id
      description              = "Adminer from ALB"
    }
    to_rds = {
      type                     = "egress"
      from_port                = 5432
      to_port                  = 5432
      protocol                 = "tcp"
      source_security_group_id = module.security.rds_security_group_id
      description              = "Allow ECS to connect to RDS"
    }
  }

  # ---------------------------------------------------------------------------
  # IAM - Task role permissions (application-level)
  # ---------------------------------------------------------------------------
  tasks_iam_role_statements = [
    {
      sid       = "SSMReadParams"
      actions   = ["ssm:GetParameter", "ssm:GetParameters"]
      resources = ["arn:aws:ssm:${var.aws_region}:*:parameter/${var.environment}/${var.project}/*"]
    },
    {
      sid       = "EventBridgePutEvents"
      actions   = ["events:PutEvents"]
      resources = ["arn:aws:events:${var.aws_region}:*:event-bus/${var.project}-${var.environment}-*"]
    }
  ]

  # ---------------------------------------------------------------------------
  # Service Discovery
  # ---------------------------------------------------------------------------
  service_registries = var.enable_service_discovery ? {
    registry_arn = module.service_discovery.backend_service_arn
  } : null

  # ---------------------------------------------------------------------------
  # Autoscaling (production only)
  # ---------------------------------------------------------------------------
  enable_autoscaling       = var.environment == "production"
  autoscaling_min_capacity = var.environment == "production" ? 2 : 1
  autoscaling_max_capacity = var.environment == "production" ? 10 : 3

  autoscaling_policies = var.environment == "production" ? {
    cpu = {
      policy_type = "TargetTrackingScaling"
      target_tracking_scaling_policy_configuration = {
        predefined_metric_specification = {
          predefined_metric_type = "ECSServiceAverageCPUUtilization"
        }
        target_value       = 70
        scale_in_cooldown  = 300
        scale_out_cooldown = 60
      }
    }
    memory = {
      policy_type = "TargetTrackingScaling"
      target_tracking_scaling_policy_configuration = {
        predefined_metric_specification = {
          predefined_metric_type = "ECSServiceAverageMemoryUtilization"
        }
        target_value       = 80
        scale_in_cooldown  = 300
        scale_out_cooldown = 60
      }
    }
  } : {}
}


# ============================================================================
# Additional Security Group Rules
# ============================================================================
# Allow the Fargate service SG to reach RDS

resource "aws_security_group_rule" "fargate_to_rds" {
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  security_group_id        = module.security.rds_security_group_id
  source_security_group_id = module.ecs_fargate.security_group_id
  description              = "PostgreSQL from Fargate tasks"
}
