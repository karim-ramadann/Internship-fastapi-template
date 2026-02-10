# ==============================================================================
# ECS EC2 Cluster Wrapper Module
# ==============================================================================
# This wrapper provides a reusable ECS cluster with EC2 capacity provider.
# Task definitions and services belong in the root as business logic.

locals {
  name_prefix = "${var.context.project}-${var.context.environment}"
}

# Data source for latest ECS-optimized AMI
data "aws_ami" "ecs_optimized" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-ecs-hvm-*-x86_64-ebs"]
  }
}

# ==============================================================================
# ECS Cluster
# ==============================================================================

resource "aws_ecs_cluster" "main" {
  name = local.name_prefix

  setting {
    name  = "containerInsights"
    value = var.enable_container_insights ? "enabled" : "disabled"
  }

  tags = merge(
    var.context.common_tags,
    {
      Name = local.name_prefix
    }
  )
}

# ==============================================================================
# EC2 Auto Scaling Group for ECS
# ==============================================================================

# Launch Template for ECS EC2 instances
resource "aws_launch_template" "ecs" {
  name_prefix   = "${local.name_prefix}-ecs-"
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
        Name = "${local.name_prefix}-ecs-instance"
      }
    )
  }
}

# Auto Scaling Group using community module
module "autoscaling" {
  source  = "terraform-aws-modules/autoscaling/aws"
  version = "~> 7.0"

  name = "${local.name_prefix}-ecs-asg"

  min_size         = var.asg_min_size
  max_size         = var.asg_max_size
  desired_capacity = var.asg_desired_capacity

  vpc_zone_identifier       = var.private_subnet_ids
  health_check_type         = "EC2"
  health_check_grace_period = 300

  launch_template_name    = aws_launch_template.ecs.name
  launch_template_version = "$Latest"

  protect_from_scale_in = true

  tags = var.context.common_tags
}

# ==============================================================================
# ECS Capacity Provider
# ==============================================================================

resource "aws_ecs_capacity_provider" "main" {
  name = "${local.name_prefix}-capacity-provider"

  auto_scaling_group_provider {
    auto_scaling_group_arn         = module.autoscaling.autoscaling_group_arn
    managed_termination_protection = "ENABLED"

    managed_scaling {
      status                    = "ENABLED"
      target_capacity           = var.capacity_provider_target
      minimum_scaling_step_size = 1
      maximum_scaling_step_size = 100
    }
  }

  tags = var.context.common_tags
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
