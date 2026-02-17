# ============================================================================
# ECS Cluster and Service
# ============================================================================

# ECS Cluster
module "ecs_cluster" {
  source = "../modules/aws_ecs_cluster"

  context = local.context
  name    = "cluster"

  # Cluster configuration
  cluster_setting = [
    {
      name  = "containerInsights"
      value = "enabled"
    }
  ]

  # Capacity providers
  cluster_capacity_providers = ["FARGATE", "FARGATE_SPOT"]

  # CloudWatch logging
  create_cloudwatch_log_group            = true
  cloudwatch_log_group_retention_in_days = var.log_retention_days

  tags = {
    Component = "ecs-cluster"
  }
}

# CloudWatch Log Group for Backend Service
resource "aws_cloudwatch_log_group" "backend" {
  name              = "/ecs/${var.environment}/${var.project}/backend"
  retention_in_days = var.log_retention_days

  tags = merge(
    local.context.common_tags,
    {
      Name      = "${var.project}-backend-logs-${var.environment}"
      Component = "logging"
    }
  )
}

# ECS Service for Backend
module "ecs_service_backend" {
  source = "../modules/aws_ecs_service"

  context = local.context
  name    = "backend"

  cluster_arn = module.ecs_cluster.cluster_arn

  # Launch type and capacity
  launch_type      = "FARGATE"
  platform_version = "LATEST"

  # Task definition
  cpu                      = var.task_cpu
  memory                   = var.task_memory
  requires_compatibilities = ["FARGATE"]

  # Container definitions
  container_definitions = {
    backend = {
      name      = "backend"
      image     = "${module.ecr_backend.repository_url}:${var.backend_image_tag}"
      essential = true

      portMappings = [
        {
          name          = "backend"
          containerPort = 8000
          hostPort      = 8000
          protocol      = "tcp"
          appProtocol   = "http"
        }
      ]

      # Environment variables from .env file
      environment = [
        {
          name  = "DOMAIN"
          value = var.domain
        },
        {
          name  = "FRONTEND_HOST"
          value = var.frontend_host
        },
        {
          name  = "ENVIRONMENT"
          value = var.environment
        },
        {
          name  = "PROJECT_NAME"
          value = var.project
        },
        {
          name  = "BACKEND_CORS_ORIGINS"
          value = var.backend_cors_origins
        },
        {
          name  = "FIRST_SUPERUSER"
          value = var.first_superuser
        },
        {
          name  = "SMTP_HOST"
          value = var.smtp_host
        },
        {
          name  = "SMTP_USER"
          value = var.smtp_user
        },
        {
          name  = "SMTP_TLS"
          value = tostring(var.smtp_tls)
        },
        {
          name  = "SMTP_SSL"
          value = tostring(var.smtp_ssl)
        },
        {
          name  = "SMTP_PORT"
          value = tostring(var.smtp_port)
        },
        {
          name  = "EMAILS_FROM_EMAIL"
          value = var.emails_from_email
        },
        {
          name  = "SENTRY_DSN"
          value = var.sentry_dsn
        },
        {
          name  = "POSTGRES_SERVER"
          value = module.database.rds_address
        },
        {
          name  = "POSTGRES_PORT"
          value = tostring(module.database.rds_port)
        },
        {
          name  = "POSTGRES_DB"
          value = var.db_name
        },
        {
          name  = "POSTGRES_USER"
          value = var.db_username
        }
      ]

      # Secrets from AWS Secrets Manager
      secrets = [
        {
          name      = "SECRET_KEY"
          valueFrom = "${aws_secretsmanager_secret.app_secrets.arn}:secret_key::"
        },
        {
          name      = "FIRST_SUPERUSER_PASSWORD"
          valueFrom = "${aws_secretsmanager_secret.app_secrets.arn}:first_superuser_password::"
        },
        {
          name      = "SMTP_PASSWORD"
          valueFrom = "${aws_secretsmanager_secret.app_secrets.arn}:smtp_password::"
        },
        {
          name      = "POSTGRES_PASSWORD"
          valueFrom = "${module.database.secrets_manager_secret_arn}:password::"
        }
      ]

      # CloudWatch Logs
      # Naming standard: /service/env/project/component (hierarchical)
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.backend.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ecs"
        }
      }

      # Health check
      healthCheck = {
        command     = ["CMD-SHELL", "curl -f http://localhost:8000/api/v1/utils/health-check/ || exit 1"]
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 60
      }
    }
  }

  # Networking
  subnet_ids            = module.vpc.private_subnet_ids
  create_security_group = false
  security_group_ids    = [module.ecs_security_group.security_group_id]
  assign_public_ip      = false

  # Service configuration
  desired_count                      = var.ecs_desired_count
  deployment_minimum_healthy_percent = 100
  deployment_maximum_percent         = 200
  enable_execute_command             = var.environment != "production"
  enable_ecs_managed_tags            = true
  propagate_tags                     = "SERVICE"

  # Deployment circuit breaker
  deployment_circuit_breaker = {
    enable   = true
    rollback = true
  }

  # Load balancer
  load_balancer = {
    backend = {
      container_name   = "backend"
      container_port   = 8000
      target_group_arn = module.alb.target_groups["backend"].arn
    }
  }

  # Health check grace period for ALB health checks
  health_check_grace_period_seconds = 60

  # Auto-scaling
  enable_autoscaling       = var.enable_autoscaling
  autoscaling_min_capacity = var.autoscaling_min_capacity
  autoscaling_max_capacity = var.autoscaling_max_capacity

  autoscaling_policies = var.enable_autoscaling ? {
    cpu = {
      policy_type = "TargetTrackingScaling"
      target_tracking_scaling_policy_configuration = {
        predefined_metric_specification = {
          predefined_metric_type = "ECSServiceAverageCPUUtilization"
        }
        target_value = 70.0
      }
    }
    memory = {
      policy_type = "TargetTrackingScaling"
      target_tracking_scaling_policy_configuration = {
        predefined_metric_specification = {
          predefined_metric_type = "ECSServiceAverageMemoryUtilization"
        }
        target_value = 80.0
      }
    }
  } : {}

  # IAM roles
  create_task_exec_iam_role = true
  create_tasks_iam_role     = true

  # Task execution role needs access to Secrets Manager
  task_exec_secret_arns = [
    module.database.secrets_manager_secret_arn,
    "${module.database.secrets_manager_secret_arn}:*",
    aws_secretsmanager_secret.app_secrets.arn,
    "${aws_secretsmanager_secret.app_secrets.arn}:*"
  ]

  tags = {
    Component = "ecs-service"
  }
}
