# ==============================================================================
# Security Module - Security Groups & IAM Roles
# ==============================================================================
# ECS-related security groups and IAM roles are managed by the ecs-fargate
# module. This module handles ALB, RDS, Lambda, and Step Functions security.

# ============================================================================
# ALB Security Group
# ============================================================================

module "alb_security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 5.0"

  name        = "${var.context.project}-${var.context.environment}-alb-sg"
  description = "Security group for Application Load Balancer"
  vpc_id      = var.vpc_id

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
      description = "HTTP from anywhere (redirect to HTTPS)"
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
    var.context.common_tags,
    {
      Name = "${var.context.project}-${var.context.environment}-alb-sg"
    }
  )
}

# ============================================================================
# RDS Security Group
# ============================================================================
# Ingress rules for ECS Fargate are added in compute.tf (fargate_to_rds).
# Lambda ingress is added below.

module "rds_security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 5.0"

  name        = "${var.context.project}-${var.context.environment}-rds-sg"
  description = "Security group for RDS PostgreSQL"
  vpc_id      = var.vpc_id

  tags = merge(
    var.context.common_tags,
    {
      Name = "${var.context.project}-${var.context.environment}-rds-sg"
    }
  )
}

# ============================================================================
# SERVERLESS DATA PLANE - Lambda & Step Functions
# ============================================================================

# Lambda Security Group
module "lambda_security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 5.0"

  name        = "${var.context.project}-${var.context.environment}-lambda-sg"
  description = "Security group for Lambda functions"
  vpc_id      = var.vpc_id

  egress_with_cidr_blocks = [
    {
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = "0.0.0.0/0"
      description = "HTTPS outbound for AWS API calls"
    },
    {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = "0.0.0.0/0"
      description = "HTTP outbound"
    }
  ]

  tags = merge(
    var.context.common_tags,
    {
      Name = "${var.context.project}-${var.context.environment}-lambda-sg"
    }
  )
}

# Allow Lambda to access RDS
resource "aws_security_group_rule" "lambda_to_rds" {
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  security_group_id        = module.rds_security_group.security_group_id
  source_security_group_id = module.lambda_security_group.security_group_id
  description              = "PostgreSQL from Lambda functions"
}

resource "aws_security_group_rule" "lambda_to_rds_egress" {
  type                     = "egress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  security_group_id        = module.lambda_security_group.security_group_id
  source_security_group_id = module.rds_security_group.security_group_id
  description              = "Allow Lambda to connect to RDS"
}

# ============================================================================
# Lambda IAM
# ============================================================================

data "aws_iam_policy_document" "lambda_assume_role" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "lambda_execution_role" {
  name               = "${var.context.project}-${var.context.environment}-lambda-execution"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
  tags               = var.context.common_tags
}

resource "aws_iam_role_policy_attachment" "lambda_vpc_execution" {
  role       = aws_iam_role.lambda_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

data "aws_iam_policy_document" "lambda_ssm" {
  statement {
    effect = "Allow"
    actions = [
      "ssm:GetParameter",
      "ssm:GetParameters",
      "ssm:GetParametersByPath"
    ]
    resources = [
      "arn:aws:ssm:${var.context.region}:*:parameter/${var.context.environment}/${var.context.project}/*"
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "secretsmanager:GetSecretValue"
    ]
    resources = [
      "arn:aws:secretsmanager:${var.context.region}:*:secret:${var.context.environment}/${var.context.project}/*"
    ]
  }
}

resource "aws_iam_policy" "lambda_ssm" {
  name   = "${var.context.project}-${var.context.environment}-lambda-ssm"
  policy = data.aws_iam_policy_document.lambda_ssm.json
  tags   = var.context.common_tags
}

resource "aws_iam_role_policy_attachment" "lambda_ssm" {
  role       = aws_iam_role.lambda_execution_role.name
  policy_arn = aws_iam_policy.lambda_ssm.arn
}

# ============================================================================
# Step Functions IAM
# ============================================================================

data "aws_iam_policy_document" "step_functions_assume_role" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["states.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "step_functions_execution_role" {
  name               = "${var.context.project}-${var.context.environment}-step-functions-execution"
  assume_role_policy = data.aws_iam_policy_document.step_functions_assume_role.json
  tags               = var.context.common_tags
}

data "aws_iam_policy_document" "step_functions_lambda" {
  statement {
    effect = "Allow"
    actions = [
      "lambda:InvokeFunction"
    ]
    resources = [
      "arn:aws:lambda:${var.context.region}:*:function:${var.context.project}-${var.context.environment}-*"
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogDelivery",
      "logs:GetLogDelivery",
      "logs:UpdateLogDelivery",
      "logs:DeleteLogDelivery",
      "logs:ListLogDeliveries",
      "logs:PutResourcePolicy",
      "logs:DescribeResourcePolicies",
      "logs:DescribeLogGroups"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "step_functions_lambda" {
  name   = "${var.context.project}-${var.context.environment}-step-functions-lambda"
  policy = data.aws_iam_policy_document.step_functions_lambda.json
  tags   = var.context.common_tags
}

resource "aws_iam_role_policy_attachment" "step_functions_lambda" {
  role       = aws_iam_role.step_functions_execution_role.name
  policy_arn = aws_iam_policy.step_functions_lambda.arn
}
