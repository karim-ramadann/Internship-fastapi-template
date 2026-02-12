/**
 * # AWS ECS Service Module
 *
 * Thin wrapper around [terraform-aws-modules/ecs/aws](https://registry.terraform.io/modules/terraform-aws-modules/ecs/aws/latest).
 *
 * This module provides organization-wide standards for ECS services:
 * - Support for both Fargate and EC2 launch types
 * - Task definitions with container definitions
 * - Load balancer integration (ALB/NLB)
 * - Auto-scaling configuration
 * - Service Connect and Service Discovery
 * - IAM roles for tasks and task execution
 * - Security groups and network configuration
 * - CloudWatch logging
 * - Standard naming and tagging conventions
 */

locals {
  service_name = "${var.context.project}-${var.context.environment}-${var.name}"
  
  tags = merge(
    var.context.common_tags,
    {
      Name      = local.service_name
      Component = "ecs-service"
    },
    var.tags
  )
}

module "ecs_service" {
  source  = "terraform-aws-modules/ecs/aws//modules/service"
  version = "~> 7.3"

  name        = local.service_name
  cluster_arn = var.cluster_arn

  # Launch type and capacity
  launch_type                = var.launch_type
  capacity_provider_strategy = var.capacity_provider_strategy
  platform_version           = var.platform_version

  # Task definition
  create_task_definition = var.create_task_definition
  task_definition_arn    = var.task_definition_arn
  cpu                    = var.cpu
  memory                 = var.memory
  requires_compatibilities = var.requires_compatibilities
  container_definitions    = var.container_definitions
  volume                   = var.volume
  ephemeral_storage        = var.ephemeral_storage

  # Networking
  assign_public_ip   = var.assign_public_ip
  security_group_ids = var.security_group_ids
  subnet_ids         = var.subnet_ids

  # Security group rules (if creating security group)
  create_security_group           = var.create_security_group
  security_group_name             = var.security_group_name
  security_group_description      = var.security_group_description
  security_group_ingress_rules    = var.security_group_ingress_rules
  security_group_egress_rules     = var.security_group_egress_rules
  security_group_use_name_prefix  = var.security_group_use_name_prefix
  security_group_tags             = merge(local.tags, var.security_group_tags)

  # Service configuration
  desired_count                      = var.desired_count
  deployment_minimum_healthy_percent = var.deployment_minimum_healthy_percent
  deployment_maximum_percent         = var.deployment_maximum_percent
  enable_execute_command             = var.enable_execute_command
  enable_ecs_managed_tags            = var.enable_ecs_managed_tags
  propagate_tags                     = var.propagate_tags
  wait_for_steady_state              = var.wait_for_steady_state
  force_new_deployment               = var.force_new_deployment
  health_check_grace_period_seconds  = var.health_check_grace_period_seconds

  # Deployment configuration
  deployment_controller      = var.deployment_controller
  deployment_circuit_breaker = var.deployment_circuit_breaker

  # Load balancer
  load_balancer = var.load_balancer

  # Service Connect
  service_connect_configuration = var.service_connect_configuration

  # Service Discovery
  service_registries = var.service_registries

  # Auto-scaling
  enable_autoscaling               = var.enable_autoscaling
  autoscaling_min_capacity         = var.autoscaling_min_capacity
  autoscaling_max_capacity         = var.autoscaling_max_capacity
  autoscaling_policies             = var.autoscaling_policies
  autoscaling_scheduled_actions    = var.autoscaling_scheduled_actions

  # IAM roles
  create_iam_role               = var.create_iam_role
  iam_role_arn                  = var.iam_role_arn
  iam_role_name                 = var.iam_role_name
  iam_role_use_name_prefix      = var.iam_role_use_name_prefix
  iam_role_path                 = var.iam_role_path
  iam_role_description          = var.iam_role_description
  iam_role_permissions_boundary = var.iam_role_permissions_boundary
  iam_role_statements           = var.iam_role_statements
  iam_role_tags                 = merge(local.tags, var.iam_role_tags)

  create_task_exec_iam_role               = var.create_task_exec_iam_role
  task_exec_iam_role_arn                  = var.task_exec_iam_role_arn
  task_exec_iam_role_name                 = var.task_exec_iam_role_name
  task_exec_iam_role_use_name_prefix      = var.task_exec_iam_role_use_name_prefix
  task_exec_iam_role_path                 = var.task_exec_iam_role_path
  task_exec_iam_role_description          = var.task_exec_iam_role_description
  task_exec_iam_role_permissions_boundary = var.task_exec_iam_role_permissions_boundary
  task_exec_iam_role_statements           = var.task_exec_iam_role_statements
  task_exec_iam_role_tags                 = merge(local.tags, var.task_exec_iam_role_tags)

  create_tasks_iam_role               = var.create_tasks_iam_role
  tasks_iam_role_arn                  = var.tasks_iam_role_arn
  tasks_iam_role_name                 = var.tasks_iam_role_name
  tasks_iam_role_use_name_prefix      = var.tasks_iam_role_use_name_prefix
  tasks_iam_role_path                 = var.tasks_iam_role_path
  tasks_iam_role_description          = var.tasks_iam_role_description
  tasks_iam_role_permissions_boundary = var.tasks_iam_role_permissions_boundary
  tasks_iam_role_statements           = var.tasks_iam_role_statements
  tasks_iam_role_tags                 = merge(local.tags, var.tasks_iam_role_tags)

  # Task execution IAM role policies
  task_exec_ssm_param_arns       = var.task_exec_ssm_param_arns
  task_exec_secret_arns          = var.task_exec_secret_arns
  task_exec_iam_role_policies    = var.task_exec_iam_role_policies

  # Tasks IAM role policies
  tasks_iam_role_policies = var.tasks_iam_role_policies

  tags = local.tags
}
