# ============================================================================
# COMPUTE - ECS Cluster, Services, Tasks
# ============================================================================

# ECS Cluster Module (thin wrapper - just cluster infrastructure)
module "ecs_cluster" {
  source = "./modules/compute"

  context = local.context

  private_subnet_ids        = module.networking.private_subnet_ids
  ecs_security_group_id     = module.security.ecs_security_group_id
  ecs_instance_profile_name = module.security.ecs_instance_profile_name

  instance_type        = var.ec2_instance_type
  asg_min_size         = var.environment == "production" ? 2 : 1
  asg_max_size         = var.environment == "production" ? 10 : 3
  asg_desired_capacity = var.environment == "production" ? 2 : 1

  # Enable Container Insights for production
  enable_container_insights = var.environment == "production"
}

# ============================================================================
# ECS Task Definition (Business Logic - Application-Specific)
# ============================================================================

locals {
  # Common environment variables for all containers
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

  # Common secrets from SSM Parameter Store
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

# Multi-container task definition for the full-stack application
resource "aws_ecs_task_definition" "app" {
  family                   = local.name_prefix
  network_mode             = "awsvpc"
  requires_compatibilities = ["EC2"]
  cpu                      = var.task_cpu
  memory                   = var.task_memory
  execution_role_arn       = module.security.ecs_task_execution_role_arn
  task_role_arn            = module.security.ecs_task_role_arn

  container_definitions = jsonencode([
    # Prestart container - runs database migrations
    {
      name      = "prestart"
      image     = "${module.ecr.backend_repository_url}:${var.backend_image_tag}"
      essential = false
      command   = ["bash", "scripts/prestart.sh"]

      environment = local.common_environment_variables
      secrets     = local.common_secrets

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = module.monitoring.prestart_log_group_name
          "awslogs-region"        = local.context.region
          "awslogs-stream-prefix" = "ecs"
        }
      }
    },
    # Backend API container
    {
      name      = "backend"
      image     = "${module.ecr.backend_repository_url}:${var.backend_image_tag}"
      essential = true

      portMappings = [
        {
          containerPort = 8000
          protocol      = "tcp"
        }
      ]

      dependsOn = [
        {
          containerName = "prestart"
          condition     = "SUCCESS"
        }
      ]

      environment = local.common_environment_variables
      secrets     = local.common_secrets

      healthCheck = {
        command     = ["CMD-SHELL", "curl -f http://localhost:8000/api/v1/utils/health-check/ || exit 1"]
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 60
      }

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = module.monitoring.backend_log_group_name
          "awslogs-region"        = local.context.region
          "awslogs-stream-prefix" = "ecs"
        }
      }
    },
    # Frontend dashboard container
    {
      name      = "frontend"
      image     = "${module.ecr.frontend_repository_url}:${var.frontend_image_tag}"
      essential = true

      portMappings = [
        {
          containerPort = 80
          protocol      = "tcp"
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = module.monitoring.frontend_log_group_name
          "awslogs-region"        = local.context.region
          "awslogs-stream-prefix" = "ecs"
        }
      }
    },
    # Adminer database management container
    {
      name      = "adminer"
      image     = "adminer:latest"
      essential = false

      portMappings = [
        {
          containerPort = 8080
          protocol      = "tcp"
        }
      ]

      environment = [
        { name = "ADMINER_DESIGN", value = "pepa-linha-dark" }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = module.monitoring.adminer_log_group_name
          "awslogs-region"        = local.context.region
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])

  tags = local.context.common_tags
}

# ============================================================================
# ECS Service (Business Logic - Application-Specific Load Balancer Config)
# ============================================================================

resource "aws_ecs_service" "app" {
  name            = "${local.name_prefix}-service"
  cluster         = module.ecs_cluster.cluster_id
  task_definition = aws_ecs_task_definition.app.arn
  desired_count   = var.ecs_desired_count
  launch_type     = "EC2"

  deployment_configuration {
    minimum_healthy_percent = 50
    maximum_percent         = 200
  }

  network_configuration {
    subnets          = module.networking.private_subnet_ids
    security_groups  = [module.security.ecs_security_group_id]
    assign_public_ip = false
  }

  # Load balancer configuration for backend API
  load_balancer {
    target_group_arn = aws_lb_target_group.backend.arn
    container_name   = "backend"
    container_port   = 8000
  }

  # Load balancer configuration for frontend dashboard
  load_balancer {
    target_group_arn = aws_lb_target_group.frontend.arn
    container_name   = "frontend"
    container_port   = 80
  }

  # Load balancer configuration for adminer
  load_balancer {
    target_group_arn = aws_lb_target_group.adminer.arn
    container_name   = "adminer"
    container_port   = 8080
  }

  # Service discovery for backend (optional)
  dynamic "service_registries" {
    for_each = var.enable_service_discovery ? [1] : []
    content {
      registry_arn = module.service_discovery.backend_service_arn
    }
  }

  health_check_grace_period_seconds = 180

  tags = merge(
    local.context.common_tags,
    {
      Name = "${local.name_prefix}-service"
    }
  )

  lifecycle {
    ignore_changes = [desired_count]
  }

  depends_on = [
    module.load_balancer,
    aws_lb_listener.https,
    aws_lb_target_group.backend,
    aws_lb_target_group.frontend,
    aws_lb_target_group.adminer
  ]
}
