# ==============================================================================
# ECS Fargate Wrapper Module
# ==============================================================================
# Calls the community module's cluster and service submodules directly to avoid
# the for_each unknown-key issue that occurs when container definitions with
# computed values flow through the top-level module's services map.
#
# Upstream: https://registry.terraform.io/modules/terraform-aws-modules/ecs/aws/latest

locals {
  name_prefix = "${var.context.project}-${var.context.environment}"

  sg_rules = { for k, v in var.security_group_rules : k => {
    type                     = v.type
    description              = v.description
    from_port                = v.from_port
    to_port                  = v.to_port
    protocol                 = v.protocol
    cidr_blocks              = v.cidr_ipv4 != null ? [v.cidr_ipv4] : null
    source_security_group_id = v.source_security_group_id
  } }
}

# ==============================================================================
# Cluster (community submodule)
# ==============================================================================

module "cluster" {
  source = "terraform-aws-modules/ecs/aws/modules/cluster"
  version = "~> 5.0"

  cluster_name = "${local.name_prefix}-cluster"

  cluster_settings = [
    {
      name  = "containerInsights"
      value = var.enable_container_insights ? "enabled" : "disabled"
    }
  ]

  create_cloudwatch_log_group            = var.create_cloudwatch_log_group
  cloudwatch_log_group_retention_in_days = var.cloudwatch_log_group_retention_in_days

  default_capacity_provider_use_fargate = true

  fargate_capacity_providers = {
    FARGATE = {
      default_capacity_provider_strategy = {
        base   = 1
        weight = 100
      }
    }
    FARGATE_SPOT = {
      default_capacity_provider_strategy = {
        weight = 0
      }
    }
  }

  tags = var.context.common_tags
}

# ==============================================================================
# Service (community submodule) — called directly so container_definitions
# keys are visible to for_each at plan time
# ==============================================================================

module "service" {
  source  = "terraform-aws-modules/ecs/aws/modules/service"
  version = "~> 5.0"

  name        = "${local.name_prefix}-service"
  cluster_arn = module.cluster.arn

  # Task definition
  cpu                      = var.task_cpu
  memory                   = var.task_memory
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"

  runtime_platform = {
    cpu_architecture        = "X86_64"
    operating_system_family = "LINUX"
  }

  # Container definitions — passed directly, keys are static
  container_definitions = var.container_definitions

  container_definition_defaults = {
    enable_cloudwatch_logging              = true
    create_cloudwatch_log_group            = true
    cloudwatch_log_group_retention_in_days = var.log_retention_days
  }

  # Capacity provider strategy
  capacity_provider_strategy = {
    fargate = {
      base              = 1
      weight            = 100
      capacity_provider = "FARGATE"
    }
  }

  # Service configuration
  desired_count                      = var.desired_count
  deployment_maximum_percent         = var.deployment_maximum_percent
  deployment_minimum_healthy_percent = var.deployment_minimum_healthy_percent
  force_new_deployment               = var.force_new_deployment
  wait_for_steady_state              = var.wait_for_steady_state
  ignore_task_definition_changes     = var.ignore_task_definition_changes

  deployment_circuit_breaker = var.enable_deployment_circuit_breaker ? {
    enable   = true
    rollback = true
  } : {}

  health_check_grace_period_seconds = length(var.load_balancers) > 0 ? var.health_check_grace_period_seconds : null

  # Load balancer attachments
  load_balancer = var.load_balancers

  # Networking
  assign_public_ip = var.assign_public_ip
  subnet_ids       = var.subnet_ids

  # Security group
  create_security_group = true
  security_group_name   = "${local.name_prefix}-ecs-fargate-sg"
  security_group_rules  = local.sg_rules

  # Service discovery
  service_registries = var.service_registries != null ? var.service_registries : {}

  # Task execution IAM role
  create_task_exec_iam_role = true
  task_exec_iam_role_name   = "${local.name_prefix}-fargate-task-exec"
  create_task_exec_policy   = true
  task_exec_ssm_param_arns  = var.task_exec_ssm_param_arns
  task_exec_secret_arns     = var.task_exec_secret_arns

  # Task IAM role
  create_tasks_iam_role     = true
  tasks_iam_role_name       = "${local.name_prefix}-fargate-task-role"
  tasks_iam_role_statements = var.tasks_iam_role_statements

  # Autoscaling
  enable_autoscaling       = var.enable_autoscaling
  autoscaling_min_capacity = var.autoscaling_min_capacity
  autoscaling_max_capacity = var.autoscaling_max_capacity
  autoscaling_policies     = var.autoscaling_policies

  tags = var.context.common_tags
}
