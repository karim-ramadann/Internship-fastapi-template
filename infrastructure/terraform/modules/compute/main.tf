# Data source for latest ECS-optimized AMI
data "aws_ami" "ecs_optimized" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-ecs-hvm-*-x86_64-ebs"]
  }
}

# ECS Cluster
resource "aws_ecs_cluster" "main" {
  name = "${var.context.project}-${var.context.environment}"

  setting {
    name  = "containerInsights"
    value = var.context.environment == "production" ? "enabled" : "disabled"
  }

  tags = merge(
    var.context.common_tags,
    {
      Name = "${var.context.project}-${var.context.environment}"
    }
  )
}

# ECS Cluster Capacity Providers
resource "aws_ecs_cluster_capacity_providers" "main" {
  cluster_name = aws_ecs_cluster.main.name

  capacity_providers = [aws_ecs_capacity_provider.main.name]

  default_capacity_provider_strategy {
    base              = 1
    weight            = 100
    capacity_provider = aws_ecs_capacity_provider.main.name
  }
}

# Launch Template for ECS EC2 instances
resource "aws_launch_template" "ecs" {
  name_prefix   = "${var.context.project}-${var.context.environment}-ecs-"
  image_id      = data.aws_ami.ecs_optimized.id
  instance_type = var.instance_type

  iam_instance_profile {
    name = var.ecs_instance_profile_name
  }

  vpc_security_group_ids = [var.ecs_security_group_id]

  user_data = base64encode(templatefile("${path.module}/user-data.sh", {
    cluster_name = aws_ecs_cluster.main.name
  }))

  monitoring {
    enabled = true
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  tag_specifications {
    resource_type = "instance"
    tags = merge(
      var.context.common_tags,
      {
        Name = "${var.context.project}-${var.context.environment}-ecs-instance"
      }
    )
  }
}

# Auto Scaling Group for ECS instances
module "autoscaling" {
  source  = "terraform-aws-modules/autoscaling/aws"
  version = "~> 7.0"

  name = "${var.context.project}-${var.context.environment}-ecs-asg"

  min_size         = var.asg_min_size
  max_size         = var.asg_max_size
  desired_capacity = var.asg_desired_capacity

  vpc_zone_identifier = var.private_subnet_ids
  health_check_type   = "EC2"
  health_check_grace_period = 300

  launch_template_name    = aws_launch_template.ecs.name
  launch_template_version = "$Latest"

  protect_from_scale_in = true

  tags = var.context.common_tags
}

# ECS Capacity Provider
resource "aws_ecs_capacity_provider" "main" {
  name = "${var.context.project}-${var.context.environment}-capacity-provider"

  auto_scaling_group_provider {
    auto_scaling_group_arn         = module.autoscaling.autoscaling_group_arn
    managed_termination_protection = "ENABLED"

    managed_scaling {
      status                    = "ENABLED"
      target_capacity           = 100
      minimum_scaling_step_size = 1
      maximum_scaling_step_size = 100
    }
  }

  tags = var.context.common_tags
}

# ECS Task Definition (multi-container)
resource "aws_ecs_task_definition" "app" {
  family                   = "${var.context.project}-${var.context.environment}"
  network_mode             = "awsvpc"
  requires_compatibilities = ["EC2"]
  cpu                      = var.task_cpu
  memory                   = var.task_memory
  execution_role_arn       = var.ecs_task_execution_role_arn
  task_role_arn            = var.ecs_task_role_arn

  container_definitions = jsonencode([
    {
      name      = "prestart"
      image     = "${var.backend_repository_url}:${var.backend_image_tag}"
      essential = false
      command   = ["bash", "scripts/prestart.sh"]

      environment = concat(var.common_environment_variables, [
        { name = "POSTGRES_SERVER", value = var.rds_address }
      ])

      secrets = var.common_secrets

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = var.prestart_log_group_name
          "awslogs-region"        = var.context.region
          "awslogs-stream-prefix" = "ecs"
        }
      }
    },
    {
      name      = "backend"
      image     = "${var.backend_repository_url}:${var.backend_image_tag}"
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

      environment = concat(var.common_environment_variables, [
        { name = "POSTGRES_SERVER", value = var.rds_address }
      ])

      secrets = var.common_secrets

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
          "awslogs-group"         = var.backend_log_group_name
          "awslogs-region"        = var.context.region
          "awslogs-stream-prefix" = "ecs"
        }
      }
    },
    {
      name      = "frontend"
      image     = "${var.frontend_repository_url}:${var.frontend_image_tag}"
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
          "awslogs-group"         = var.frontend_log_group_name
          "awslogs-region"        = var.context.region
          "awslogs-stream-prefix" = "ecs"
        }
      }
    },
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
          "awslogs-group"         = var.adminer_log_group_name
          "awslogs-region"        = var.context.region
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])

  tags = var.context.common_tags
}

# ECS Service
resource "aws_ecs_service" "app" {
  name            = "${var.context.project}-${var.context.environment}-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.app.arn
  desired_count   = var.desired_count
  launch_type     = "EC2"

  deployment_configuration {
    minimum_healthy_percent = 50
    maximum_percent         = 200
  }

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [var.ecs_security_group_id]
    assign_public_ip = false
  }

  # Load balancer configuration for backend
  load_balancer {
    target_group_arn = var.backend_target_group_arn
    container_name   = "backend"
    container_port   = 8000
  }

  # Load balancer configuration for frontend
  load_balancer {
    target_group_arn = var.frontend_target_group_arn
    container_name   = "frontend"
    container_port   = 80
  }

  # Load balancer configuration for adminer
  load_balancer {
    target_group_arn = var.adminer_target_group_arn
    container_name   = "adminer"
    container_port   = 8080
  }

  # Service discovery (optional)
  dynamic "service_registries" {
    for_each = var.service_discovery_registry_arn != null ? [1] : []
    content {
      registry_arn = var.service_discovery_registry_arn
    }
  }

  health_check_grace_period_seconds = 180

  # Ensure ALB is ready before service
  depends_on = [
    var.backend_target_group_arn,
    var.frontend_target_group_arn,
    var.adminer_target_group_arn
  ]

  tags = merge(
    var.context.common_tags,
    {
      Name = "${var.context.project}-${var.context.environment}-service"
    }
  )

  lifecycle {
    ignore_changes = [desired_count]
  }
}
