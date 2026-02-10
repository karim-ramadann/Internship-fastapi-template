# ALB Security Group
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

# ECS Security Group
module "ecs_security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 5.0"

  name        = "${var.context.project}-${var.context.environment}-ecs-sg"
  description = "Security group for ECS tasks"
  vpc_id      = var.vpc_id

  computed_ingress_with_source_security_group_id = [
    {
      from_port                = 8000
      to_port                  = 8000
      protocol                 = "tcp"
      source_security_group_id = module.alb_security_group.security_group_id
      description              = "Backend from ALB"
    },
    {
      from_port                = 80
      to_port                  = 80
      protocol                 = "tcp"
      source_security_group_id = module.alb_security_group.security_group_id
      description              = "Frontend from ALB"
    },
    {
      from_port                = 8080
      to_port                  = 8080
      protocol                 = "tcp"
      source_security_group_id = module.alb_security_group.security_group_id
      description              = "Adminer from ALB"
    }
  ]
  number_of_computed_ingress_with_source_security_group_id = 3

  egress_with_cidr_blocks = [
    {
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = "0.0.0.0/0"
      description = "HTTPS to internet (for pulling images, external APIs)"
    },
    {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = "0.0.0.0/0"
      description = "HTTP to internet"
    }
  ]

  tags = merge(
    var.context.common_tags,
    {
      Name = "${var.context.project}-${var.context.environment}-ecs-sg"
    }
  )
}

# RDS Security Group
module "rds_security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 5.0"

  name        = "${var.context.project}-${var.context.environment}-rds-sg"
  description = "Security group for RDS PostgreSQL"
  vpc_id      = var.vpc_id

  computed_ingress_with_source_security_group_id = [
    {
      from_port                = 5432
      to_port                  = 5432
      protocol                 = "tcp"
      source_security_group_id = module.ecs_security_group.security_group_id
      description              = "PostgreSQL from ECS tasks"
    }
  ]
  number_of_computed_ingress_with_source_security_group_id = 1

  tags = merge(
    var.context.common_tags,
    {
      Name = "${var.context.project}-${var.context.environment}-rds-sg"
    }
  )
}

# Allow ECS to RDS egress rule
resource "aws_security_group_rule" "ecs_to_rds" {
  type                     = "egress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  security_group_id        = module.ecs_security_group.security_group_id
  source_security_group_id = module.rds_security_group.security_group_id
  description              = "Allow ECS to connect to RDS"
}

# IAM Role for ECS Task Execution
data "aws_iam_policy_document" "ecs_task_execution_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "ecs_task_execution_role" {
  name               = "${var.context.project}-${var.context.environment}-ecs-task-execution-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_execution_assume_role.json

  tags = var.context.common_tags
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Custom policy for SSM Parameter Store access
data "aws_iam_policy_document" "ecs_task_execution_ssm" {
  statement {
    effect = "Allow"
    actions = [
      "ssm:GetParameters",
      "ssm:GetParameter",
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

  statement {
    effect = "Allow"
    actions = [
      "kms:Decrypt"
    ]
    resources = ["*"]
    condition {
      test     = "StringEquals"
      variable = "kms:ViaService"
      values   = ["secretsmanager.${var.context.region}.amazonaws.com"]
    }
  }
}

resource "aws_iam_policy" "ecs_task_execution_ssm" {
  name        = "${var.context.project}-${var.context.environment}-ecs-task-execution-ssm-policy"
  description = "Allow ECS task execution to read SSM parameters and secrets"
  policy      = data.aws_iam_policy_document.ecs_task_execution_ssm.json

  tags = var.context.common_tags
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_ssm" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = aws_iam_policy.ecs_task_execution_ssm.arn
}

# IAM Role for ECS Task (application permissions)
resource "aws_iam_role" "ecs_task_role" {
  name               = "${var.context.project}-${var.context.environment}-ecs-task-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_execution_assume_role.json

  tags = var.context.common_tags
}

# Policy for ECS task to access SSM parameters (if needed by application)
data "aws_iam_policy_document" "ecs_task_ssm" {
  statement {
    effect = "Allow"
    actions = [
      "ssm:GetParameter",
      "ssm:GetParameters"
    ]
    resources = [
      "arn:aws:ssm:${var.context.region}:*:parameter/${var.context.environment}/${var.context.project}/*"
    ]
  }
}

resource "aws_iam_policy" "ecs_task_ssm" {
  name        = "${var.context.project}-${var.context.environment}-ecs-task-ssm-policy"
  description = "Allow ECS task to read SSM parameters"
  policy      = data.aws_iam_policy_document.ecs_task_ssm.json

  tags = var.context.common_tags
}

resource "aws_iam_role_policy_attachment" "ecs_task_ssm" {
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = aws_iam_policy.ecs_task_ssm.arn
}

# IAM Role for EC2 instances in ECS cluster
data "aws_iam_policy_document" "ecs_instance_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "ecs_instance_role" {
  name               = "${var.context.project}-${var.context.environment}-ecs-instance-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_instance_assume_role.json

  tags = var.context.common_tags
}

resource "aws_iam_role_policy_attachment" "ecs_instance_role_policy" {
  role       = aws_iam_role.ecs_instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_role_policy_attachment" "ecs_instance_ssm_policy" {
  role       = aws_iam_role.ecs_instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ecs_instance_profile" {
  name = "${var.context.project}-${var.context.environment}-ecs-instance-profile"
  role = aws_iam_role.ecs_instance_role.name

  tags = var.context.common_tags
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

# Lambda Execution Role
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

# Lambda VPC Access (for private subnet execution)
resource "aws_iam_role_policy_attachment" "lambda_vpc_execution" {
  role       = aws_iam_role.lambda_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

# Lambda SSM Parameter Access
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

# Step Functions Execution Role
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

# Step Functions can invoke Lambda
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

# ECS Task Role - Add EventBridge PutEvents Permission
data "aws_iam_policy_document" "ecs_task_eventbridge" {
  statement {
    effect = "Allow"
    actions = [
      "events:PutEvents"
    ]
    resources = [
      "arn:aws:events:${var.context.region}:*:event-bus/${var.context.project}-${var.context.environment}-*"
    ]
  }
}

resource "aws_iam_policy" "ecs_task_eventbridge" {
  name   = "${var.context.project}-${var.context.environment}-ecs-eventbridge"
  policy = data.aws_iam_policy_document.ecs_task_eventbridge.json
  tags   = var.context.common_tags
}

resource "aws_iam_role_policy_attachment" "ecs_task_eventbridge" {
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = aws_iam_policy.ecs_task_eventbridge.arn
}
