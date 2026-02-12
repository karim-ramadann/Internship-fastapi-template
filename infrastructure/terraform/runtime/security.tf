# ============================================================================
# Security Groups
# ============================================================================

# ALB Security Group
module "alb_security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 5.0"

  # Naming standard: project-resource-name-env (flat)
  name        = "${var.project}-alb-sg-${var.environment}"
  description = "Security group for Application Load Balancer"
  vpc_id      = module.vpc.vpc_id

  ingress_with_cidr_blocks = [
    {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = "0.0.0.0/0"
      description = "HTTP from anywhere"
    }
  ]

  egress_with_cidr_blocks = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = "0.0.0.0/0"
      description = "Allow all outbound"
    }
  ]

  tags = merge(
    local.context.common_tags,
    {
      Name      = "${var.project}-alb-sg-${var.environment}"
      Component = "security"
    }
  )
}

# RDS Security Group
module "rds_security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 5.0"

  # Naming standard: project-resource-name-env (flat)
  name        = "${var.project}-rds-sg-${var.environment}"
  description = "Security group for RDS PostgreSQL"
  vpc_id      = module.vpc.vpc_id

  # No ingress rules defined here - will be added via security group rules below

  tags = merge(
    local.context.common_tags,
    {
      Name      = "${var.project}-rds-sg-${var.environment}"
      Component = "security"
    }
  )
}

# ECS Security Group
module "ecs_security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 5.0"

  # Naming standard: project-resource-name-env (flat)
  name        = "${var.project}-ecs-sg-${var.environment}"
  description = "Security group for ECS Fargate tasks"
  vpc_id      = module.vpc.vpc_id

  # No ingress rules defined here - will be added via security group rules below

  egress_with_cidr_blocks = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = "0.0.0.0/0"
      description = "Allow all outbound"
    }
  ]

  tags = merge(
    local.context.common_tags,
    {
      Name      = "${var.project}-ecs-sg-${var.environment}"
      Component = "security"
    }
  )
}

# Security Group Rules

# Allow ALB to communicate with ECS tasks on container port
resource "aws_security_group_rule" "alb_to_ecs" {
  type                     = "ingress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  security_group_id        = module.ecs_security_group.security_group_id
  source_security_group_id = module.alb_security_group.security_group_id
  description              = "Allow ALB to communicate with ECS tasks"
}

# Allow ECS tasks to communicate with RDS
resource "aws_security_group_rule" "ecs_to_rds" {
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  security_group_id        = module.rds_security_group.security_group_id
  source_security_group_id = module.ecs_security_group.security_group_id
  description              = "Allow ECS tasks to communicate with RDS PostgreSQL"
}
