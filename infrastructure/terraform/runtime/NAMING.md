# Naming Convention Standards

This document describes the naming conventions used throughout the infrastructure code.

## Overview

The infrastructure follows a consistent naming pattern based on the type of resource:

1. **Hierarchical resources** (paths, trees): Use `env/project/service` format
2. **Flat resources** (single names): Use `resource-name-env` format

## Hierarchical Naming Pattern

**Format:** `env/project/service/component`

**Use for:**
- AWS Secrets Manager secret paths
- CloudWatch Log Group paths
- S3 key prefixes (when used hierarchically)
- Any resource that supports path-like organization

**Examples:**
```
dev/full-stack-fastapi-project/database/credentials
dev/full-stack-fastapi-project/app/secrets
staging/full-stack-fastapi-project/app/secrets
/ecs/dev/full-stack-fastapi-project/backend
/ecs/production/full-stack-fastapi-project/backend
```

**Benefits:**
- Easy to browse in AWS Console
- Natural grouping by environment
- Scales well with multiple projects
- Clear ownership and hierarchy

## Flat Naming Pattern

**Format:** `project-resource-name-env`

**Use for:**
- EC2 instances
- RDS databases
- ECS clusters
- ECS services
- Load balancers
- Security groups
- ECR repositories
- Any AWS resource with a flat name space

**Examples:**
```
full-stack-fastapi-project-alb-dev
full-stack-fastapi-project-alb-staging
full-stack-fastapi-project-alb-production
full-stack-fastapi-project-backend-tg-dev
full-stack-fastapi-project-ecs-sg-dev
full-stack-fastapi-project-rds-sg-production
full-stack-fastapi-project-db-dev
full-stack-fastapi-project-db-production
full-stack-fastapi-project-cluster-dev
full-stack-fastapi-project-backend-staging
full-stack-fastapi-project-vpc-dev
```

**Benefits:**
- Project name prefix groups all related resources together
- Resource type in the middle provides clarity
- Environment at the end makes it easy to filter
- Consistent across all flat resources
- No naming conflicts across different projects

## Implementation in Modules

### ECR Repository Module
```hcl
# modules/aws_ecr_repository/main.tf
locals {
  # Naming standard: project-resource-name-env (flat)
  repository_name = "${var.context.project}-${var.name}-${var.context.environment}"
}
```

**Example outputs:**
- `full-stack-fastapi-project-backend-dev`
- `full-stack-fastapi-project-frontend-production`

### ECS Cluster Module
```hcl
# modules/aws_ecs_cluster/main.tf
locals {
  # Naming standard: project-resource-name-env (flat)
  cluster_name = "${var.context.project}-${var.name}-${var.context.environment}"
}
```

**Example outputs:**
- `full-stack-fastapi-project-cluster-dev`
- `full-stack-fastapi-project-cluster-production`

### ECS Service Module
```hcl
# modules/aws_ecs_service/main.tf
locals {
  # Naming standard: project-resource-name-env (flat)
  service_name = "${var.context.project}-${var.name}-${var.context.environment}"
}
```

**Example outputs:**
- `full-stack-fastapi-project-backend-dev`
- `full-stack-fastapi-project-api-staging`

### Database Module
```hcl
# modules/database/main.tf

# RDS Instance
identifier = "${var.context.project}-db-${var.context.environment}"

# DB Subnet Group
name = "${var.context.project}-db-subnet-group-${var.context.environment}"

# Monitoring Role
monitoring_role_name = "${var.context.project}-rds-monitoring-role-${var.context.environment}"

# Secrets Manager (hierarchical)
name = "${var.context.environment}/${var.context.project}/database/credentials"
```

**Example outputs:**
- Flat: `full-stack-fastapi-project-db-dev`, `full-stack-fastapi-project-db-subnet-group-production`
- Hierarchical: `dev/full-stack-fastapi-project/database/credentials`

### VPC Module
```hcl
# modules/aws_vpc/main.tf
locals {
  # Naming standard: project-resource-name-env (flat)
  vpc_name = "${var.context.project}-vpc-${var.context.environment}"
}
```

**Example outputs:**
- `full-stack-fastapi-project-vpc-dev`
- `full-stack-fastapi-project-vpc-production`

## Implementation in Runtime

### Security Groups
```hcl
# runtime/security.tf
name = "${var.project}-alb-sg-${var.environment}"
name = "${var.project}-ecs-sg-${var.environment}"
name = "${var.project}-rds-sg-${var.environment}"
```

### Application Load Balancer
```hcl
# runtime/alb.tf
name = "${var.project}-alb-${var.environment}"
target_group_name = "${var.project}-backend-tg-${var.environment}"
```

### Application Secrets
```hcl
# runtime/secrets.tf
# Naming standard: env/project/service/resource (hierarchical)
name = "${var.environment}/${var.project}/app/secrets"
```

### CloudWatch Logs
```hcl
# runtime/ecs.tf
# Naming standard: /service/env/project/component (hierarchical)
awslogs-group = "/ecs/${var.environment}/${var.project}/backend"
```

## Migration from Old Naming

### Before (Incorrect)
```
# Old flat naming (env in middle)
full-stack-fastapi-project-dev-alb
full-stack-fastapi-project-dev-db
full-stack-fastapi-project-dev-cluster

# Old hierarchical naming (no env prefix)
/ecs/full-stack-fastapi-project-dev/backend
```

### After (Correct)
```
# New flat naming (env at end)
full-stack-fastapi-project-alb-dev
full-stack-fastapi-project-db-dev
full-stack-fastapi-project-cluster-dev

# New hierarchical naming (env first)
/ecs/dev/full-stack-fastapi-project/backend
```

## Benefits of This Convention

1. **Consistency**: Same pattern across all resources
2. **Readability**: Easy to understand what a resource is and which environment it belongs to
3. **Sortability**: Resources naturally sort by type (for flat) or environment (for hierarchical)
4. **Scalability**: Works well as the infrastructure grows
5. **AWS Console Friendly**: Easy to filter and search in AWS Console
6. **Automation Friendly**: Easy to parse programmatically

## Rules Summary

### Hierarchical Resources (Paths)
- ✅ Format: `env/project/service/component`
- ✅ Examples: Secrets Manager, CloudWatch Logs, S3 prefixes
- ✅ Pattern: Environment comes **first**

### Flat Resources (Single Names)
- ✅ Format: `project-resource-name-env`
- ✅ Examples: EC2, RDS, ECS, ALB, Security Groups
- ✅ Pattern: Project prefix, then resource, environment comes **last**

## Quick Reference

| Resource Type | Naming Pattern | Example |
|--------------|----------------|---------|
| Secrets Manager | `env/project/service` | `dev/myproject/app/secrets` |
| CloudWatch Logs | `/service/env/project/component` | `/ecs/dev/myproject/backend` |
| RDS Instance | `project-resource-env` | `myproject-db-dev` |
| ECS Cluster | `project-resource-env` | `myproject-cluster-production` |
| ECS Service | `project-service-env` | `myproject-backend-staging` |
| ALB | `project-resource-env` | `myproject-alb-dev` |
| Target Group | `project-resource-env` | `myproject-backend-tg-dev` |
| Security Group | `project-resource-env` | `myproject-ecs-sg-production` |
| ECR Repository | `project-name-env` | `myproject-backend-dev` |
| VPC | `project-resource-env` | `myproject-vpc-dev` |

## Validation

When creating new resources, ask:

1. **Is this a hierarchical resource?** (path-like structure)
   - Yes → Use `env/project/service` format

2. **Is this a flat resource?** (single name)
   - Yes → Use `project-resource-name-env` format

3. **Am I consistent with existing patterns?**
   - Check similar resources for the pattern
   - Update NAMING.md if creating new resource types
