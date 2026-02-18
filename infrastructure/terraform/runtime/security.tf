# ============================================================================
# Security Groups
# ============================================================================

# ALB Security Group
module "alb_security_group" {
  source = "../modules/aws_security_group"

  context     = local.context
  name        = "alb-sg"
  description = "Security group for Application Load Balancer"
  vpc_id      = module.vpc.vpc_id

  ingress_with_cidr_blocks = [
    {
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = "0.0.0.0/0"
      description = "HTTPS from anywhere"
    },
    {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = "0.0.0.0/0"
      description = "HTTP from anywhere (redirects to HTTPS)"
    }
  ]

  # ALB only needs to reach ECS targets within the VPC
  egress_with_cidr_blocks = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = var.vpc_cidr
      description = "Allow outbound to VPC only"
    }
  ]
}

# RDS Security Group
module "rds_security_group" {
  source = "../modules/aws_security_group"

  context     = local.context
  name        = "rds-sg"
  description = "Security group for RDS PostgreSQL"
  vpc_id      = module.vpc.vpc_id

  # No ingress rules defined here - will be added via security group rules below
}

# ECS Security Group
module "ecs_security_group" {
  source = "../modules/aws_security_group"

  context     = local.context
  name        = "ecs-sg"
  description = "Security group for ECS Fargate tasks"
  vpc_id      = module.vpc.vpc_id

  # No ingress rules defined here - will be added via security group rules below

  egress_with_cidr_blocks = [
    {
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = "0.0.0.0/0"
      description = "HTTPS outbound for ECR, AWS APIs, external services"
    },
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = var.vpc_cidr
      description = "All traffic within VPC (RDS, service discovery)"
    }
  ]
}

# Security Group Rules

# Allow ALB to communicate with ECS tasks on container port
resource "aws_security_group_rule" "alb_to_ecs" {
  type                     = "ingress"
  from_port                = 8000
  to_port                  = 8000
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
