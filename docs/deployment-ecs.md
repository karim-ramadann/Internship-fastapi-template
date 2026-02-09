# FastAPI Project - ECS Deployment (Production/Staging)

This document describes the ECS/Terraform deployment process for production and staging environments. For local development, continue using Docker Compose as described in `development.md`.

## Architecture Overview

The application runs on **AWS ECS** with the following components:

- **ECS Cluster**: EC2-based capacity provider running containerized services
- **Application Load Balancer (ALB)**: Handles HTTPS termination and routing
- **RDS PostgreSQL**: Managed database service
- **ECR**: Container image repositories
- **SSM Parameter Store**: Secrets management
- **Service Discovery**: AWS Cloud Map for internal container communication

## Prerequisites

Before deploying, ensure you have:

1. **AWS Account** with appropriate permissions
2. **Terraform** >= 1.5.0 installed
3. **AWS CLI** configured with credentials
4. **S3 Bucket** for Terraform state
5. **DynamoDB Table** for state locking
6. **Route53 Hosted Zone** (if using DNS records)
7. **ACM Certificate** (or ability to create one)
8. **SSM Parameters** created for secrets (see below)

## SSM Parameter Store Setup

**Critical**: Create the following SSM parameters **before** deploying infrastructure:

### Staging Secrets
```bash
aws ssm put-parameter \
  --name "/staging/full-stack-fastapi-project/SECRET_KEY" \
  --value "your-secret-key-here" \
  --type "SecureString"

aws ssm put-parameter \
  --name "/staging/full-stack-fastapi-project/FIRST_SUPERUSER_PASSWORD" \
  --value "your-password-here" \
  --type "SecureString"

aws ssm put-parameter \
  --name "/staging/full-stack-fastapi-project/SMTP_PASSWORD" \
  --value "your-smtp-password" \
  --type "SecureString"

aws ssm put-parameter \
  --name "/staging/full-stack-fastapi-project/POSTGRES_PASSWORD" \
  --value "your-db-password" \
  --type "SecureString"
```

### Production Secrets
```bash
aws ssm put-parameter \
  --name "/production/full-stack-fastapi-project/SECRET_KEY" \
  --value "your-secret-key-here" \
  --type "SecureString"

aws ssm put-parameter \
  --name "/production/full-stack-fastapi-project/FIRST_SUPERUSER_PASSWORD" \
  --value "your-password-here" \
  --type "SecureString"

aws ssm put-parameter \
  --name "/production/full-stack-fastapi-project/SMTP_PASSWORD" \
  --value "your-smtp-password" \
  --type "SecureString"

aws ssm put-parameter \
  --name "/production/full-stack-fastapi-project/POSTGRES_PASSWORD" \
  --value "your-db-password" \
  --type "SecureString"
```

**Note**: RDS password will be automatically generated and stored in SSM by Terraform, but you can override it by creating the parameter manually first.

## Infrastructure Deployment

### Initial Setup

1. **Configure Backend** (`environments/{environment}/backend.hcl`):
   ```hcl
   bucket         = "your-terraform-state-bucket"
   region         = "us-east-1"
   key            = "staging/terraform.tfstate"  # or "production/terraform.tfstate"
   dynamodb_table = "terraform-state-lock"
   encrypt        = true
   ```

2. **Configure Variables** (`environments/{environment}/terraform.tfvars`):
   - Update `domain` with your actual domain
   - Update `hosted_zone_id` with your Route53 hosted zone ID
   - Update `certificate_arn` or set `create_certificate = true`
   - Update `alarm_email` for CloudWatch notifications
   - Configure SMTP settings if needed

### Deploy Infrastructure

```bash
cd infrastructure/terraform

# Initialize Terraform
terraform init -backend-config=environments/staging/backend.hcl

# Review plan
terraform plan -var-file=environments/staging/terraform.tfvars

# Apply infrastructure
terraform apply -var-file=environments/staging/terraform.tfvars
```

### Verify Deployment

After deployment, check:

1. **ECS Cluster**: Tasks should be running
2. **ALB**: Should be accessible and routing correctly
3. **RDS**: Should be accessible from ECS tasks
4. **DNS**: Records should point to ALB

View outputs:
```bash
terraform output
```

## Application Deployment

Application deployments are handled automatically via GitHub Actions workflows:

### Staging Deployment

- **Trigger**: Push to `master` branch
- **Workflow**: `.github/workflows/deploy-staging.yml`
- **Process**:
  1. Builds Docker images for backend and frontend
  2. Pushes images to ECR
  3. Updates ECS service with new images
  4. Waits for deployment to stabilize

### Production Deployment

- **Trigger**: Publishing a release
- **Workflow**: `.github/workflows/deploy-production.yml`
- **Process**: Same as staging, but with release tags

### Manual Deployment

If you need to deploy manually:

```bash
# Build and push images
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin <account-id>.dkr.ecr.us-east-1.amazonaws.com

docker build -t <ecr-repo>/backend:latest -f backend/Dockerfile .
docker push <ecr-repo>/backend:latest

docker build -t <ecr-repo>/frontend:latest --build-arg VITE_API_URL=https://api.yourdomain.com -f frontend/Dockerfile .
docker push <ecr-repo>/frontend:latest

# Update ECS service
aws ecs update-service \
  --cluster <cluster-name> \
  --service <service-name> \
  --force-new-deployment
```

## GitHub Secrets Configuration

Configure the following secrets in GitHub repository settings:

### Required Secrets

- `AWS_ACCESS_KEY_ID`: AWS access key
- `AWS_SECRET_ACCESS_KEY`: AWS secret key
- `AWS_REGION`: AWS region (e.g., `us-east-1`)
- `AWS_ACCOUNT_ID`: AWS account ID
- `ECS_CLUSTER_STAGING`: ECS cluster name for staging
- `ECS_SERVICE_STAGING`: ECS service name for staging
- `ECS_CLUSTER_PRODUCTION`: ECS cluster name for production
- `ECS_SERVICE_PRODUCTION`: ECS service name for production
- `DOMAIN_STAGING`: Staging domain name
- `DOMAIN_PRODUCTION`: Production domain name

### Legacy Secrets (Keep for SSM Creation)

These can be kept temporarily for creating SSM parameters, then removed:
- `SECRET_KEY`
- `FIRST_SUPERUSER_PASSWORD`
- `SMTP_PASSWORD`
- `POSTGRES_PASSWORD`
- `SENTRY_DSN`

## Infrastructure Updates

Infrastructure changes are deployed via `.github/workflows/deploy-infrastructure.yml`:

- **Trigger**: Changes to `infrastructure/terraform/**`
- **Process**:
  1. Validates Terraform configuration
  2. Plans changes
  3. Applies automatically for staging
  4. Requires approval for production

## Monitoring

### CloudWatch Logs

- Backend logs: `/ecs/{project}-{environment}-backend`
- Frontend logs: `/ecs/{project}-{environment}-frontend`
- Adminer logs: `/ecs/{project}-{environment}-adminer`

### CloudWatch Alarms

Alarms are configured for:
- ECS CPU utilization (> 80%)
- ECS memory utilization (> 80%)
- RDS CPU utilization (> 80%)
- ALB 5xx errors

### Container Insights

Container Insights is enabled for the ECS cluster, providing detailed metrics and logs.

## Troubleshooting

### ECS Tasks Not Starting

1. Check CloudWatch logs for errors
2. Verify SSM parameters exist and are accessible
3. Check security groups allow traffic
4. Verify ECR images are pushed and accessible
5. Check task definition JSON is valid

### ALB Not Routing Correctly

1. Check listener rules are configured
2. Verify target groups are healthy
3. Check security groups allow ALB → ECS traffic
4. Verify DNS records point to ALB

### RDS Connection Issues

1. Verify security groups allow ECS → RDS traffic
2. Check RDS endpoint is correct
3. Verify SSM parameter for password exists
4. Check RDS is in private subnets

### Service Discovery Not Working

1. Verify Cloud Map namespace exists
2. Check service registration in ECS service
3. Verify containers are in same VPC
4. Check DNS resolution within VPC

## Rollback Procedure

### Application Rollback

```bash
# Get previous task definition revision
aws ecs describe-task-definition --task-definition <service-name> --query 'taskDefinition.revision'

# Update service to previous revision
aws ecs update-service \
  --cluster <cluster-name> \
  --service <service-name> \
  --task-definition <service-name>:<previous-revision>
```

### Infrastructure Rollback

```bash
cd infrastructure/terraform
terraform plan -var-file=environments/staging/terraform.tfvars
# Review and apply previous state if needed
```

## Cost Optimization

- **Staging**: Uses single NAT gateway, smaller instances, single AZ RDS
- **Production**: Uses multiple NAT gateways, larger instances, Multi-AZ RDS
- **ECR**: Lifecycle policies clean up old images (keeps last 10)
- **CloudWatch**: Log retention is shorter for staging (7 days vs 30 days)

## Security Best Practices

- All secrets stored in SSM Parameter Store (SecureString)
- ECS tasks run in private subnets
- RDS in private subnets with encryption enabled
- ALB terminates HTTPS (TLS 1.3)
- Security groups follow least-privilege principle
- IAM roles use minimal required permissions

## Local Development

**Important**: Docker Compose setup remains unchanged for local development. The ECS deployment is only for staging and production environments.

For local development, continue using:
```bash
docker compose up -d
```

See `development.md` for local development instructions.

## URLs

After deployment, access your application at:

- **Frontend**: `https://dashboard.{domain}`
- **Backend API**: `https://api.{domain}`
- **API Docs**: `https://api.{domain}/docs`
- **Adminer**: `https://adminer.{domain}` (if enabled)

Replace `{domain}` with your actual domain (e.g., `staging.example.com` or `example.com`).
