# Runtime Infrastructure

This directory contains the Terraform configuration for deploying the Full Stack FastAPI application infrastructure on AWS.

## Architecture Overview

The infrastructure includes:

- **VPC**: Virtual Private Cloud with public, private, and database subnets across 2 availability zones
- **RDS PostgreSQL**: Managed database instance in private subnets
- **ECS Fargate**: Serverless container orchestration for running the backend service
- **Application Load Balancer**: HTTP load balancer in public subnets
- **ECR**: Container registry for Docker images
- **Security Groups**: Network security controls for ALB, ECS, and RDS
- **Secrets Manager**: Secure storage for database credentials and application secrets

## Directory Structure

```
runtime/
├── main.tf              # Main infrastructure entry point
├── variables.tf         # Variable definitions
├── outputs.tf           # Output definitions
├── providers.tf         # Provider configuration
├── backend.tf           # S3 backend configuration
├── locals.tf            # Local values
├── datasources.tf       # Data sources
├── vpc.tf               # VPC and networking
├── security.tf          # Security groups
├── database.tf          # RDS PostgreSQL
├── alb.tf               # Application Load Balancer
├── ecr.tf               # ECR repository
├── ecs.tf               # ECS cluster and service
├── secrets.tf           # Application secrets
└── environments/
    ├── dev/
    │   └── terraform.tfvars
    ├── staging/
    │   └── terraform.tfvars
    └── production/
        └── terraform.tfvars
```

## Prerequisites

1. **AWS CLI** configured with appropriate credentials
2. **Terraform** >= 1.5.0
3. **S3 Bucket** for Terraform state (update `backend.tf` with your bucket name)
4. **Docker** (for building and pushing images)

## Environment Configuration

Each environment has its own `terraform.tfvars` file in the `environments/` directory:

- **dev**: Cost-optimized with minimal resources (db.t3.micro, single NAT Gateway, 256 CPU / 512 MB tasks)
- **staging**: Production-like with moderate resources (db.t3.small, single NAT Gateway, 512 CPU / 1024 MB tasks)
- **production**: High availability with larger resources (db.t4g.medium, Multi-AZ, NAT per AZ, 1024 CPU / 2048 MB tasks)

## Required Secrets

The following secrets must be set via environment variables or secure CI/CD variables:

```bash
export TF_VAR_secret_key="your-secret-key-here"
export TF_VAR_first_superuser_password="admin-password"
export TF_VAR_smtp_password="smtp-password"  # Optional if not using email
```

## Deployment Steps

### 1. Initialize Terraform

```bash
cd infrastructure/terraform/runtime
terraform init -backend-config="key=runtime/dev/terraform.tfstate"
```

### 2. Deploy Infrastructure

**Development:**
```bash
terraform plan -var-file=environments/dev/terraform.tfvars
terraform apply -var-file=environments/dev/terraform.tfvars
```

**Staging:**
```bash
terraform plan -var-file=environments/staging/terraform.tfvars
terraform apply -var-file=environments/staging/terraform.tfvars
```

**Production:**
```bash
terraform plan -var-file=environments/production/terraform.tfvars
terraform apply -var-file=environments/production/terraform.tfvars
```

### 3. Build and Push Docker Image

After infrastructure is deployed, get the ECR repository URL:

```bash
ECR_URL=$(terraform output -raw ecr_repository_url)
AWS_REGION=$(terraform output -raw aws_region)
```

Login to ECR:

```bash
aws ecr get-login-password --region $AWS_REGION | \
  docker login --username AWS --password-stdin $ECR_URL
```

Build and push the image:

```bash
# From the repository root
docker build -t backend:latest ./backend
docker tag backend:latest $ECR_URL:latest
docker push $ECR_URL:latest
```

### 4. Access the Application

Get the ALB DNS name:

```bash
ALB_DNS=$(terraform output -raw alb_dns_name)
echo "Backend API: http://$ALB_DNS"
echo "Health Check: http://$ALB_DNS/api/health"
```

## Useful Commands

### View Logs

```bash
CLUSTER_NAME=$(terraform output -raw ecs_cluster_name)
aws logs tail /ecs/full-stack-fastapi-project-dev/backend --follow --region eu-west-1
```

### Force New Deployment

```bash
CLUSTER_NAME=$(terraform output -raw ecs_cluster_name)
SERVICE_NAME=$(terraform output -raw ecs_service_name)
aws ecs update-service \
  --cluster $CLUSTER_NAME \
  --service $SERVICE_NAME \
  --force-new-deployment \
  --region eu-west-1
```

### View ECS Task Status

```bash
CLUSTER_NAME=$(terraform output -raw ecs_cluster_name)
SERVICE_NAME=$(terraform output -raw ecs_service_name)
aws ecs describe-services \
  --cluster $CLUSTER_NAME \
  --services $SERVICE_NAME \
  --region eu-west-1
```

### Get Database Credentials

```bash
DB_SECRET_ARN=$(terraform output -raw db_credentials_secret_arn)
aws secretsmanager get-secret-value \
  --secret-id $DB_SECRET_ARN \
  --region eu-west-1 \
  --query SecretString \
  --output text | jq
```

### Connect to RDS (via Bastion/VPN)

```bash
RDS_ENDPOINT=$(terraform output -raw rds_endpoint)
DB_NAME=$(terraform output -raw rds_database_name)

# Get password from secrets manager
DB_PASSWORD=$(aws secretsmanager get-secret-value \
  --secret-id $DB_SECRET_ARN \
  --region eu-west-1 \
  --query SecretString \
  --output text | jq -r .password)

psql -h $RDS_ENDPOINT -U postgres -d $DB_NAME
```

## Outputs

After deployment, Terraform provides these outputs:

| Output | Description |
|--------|-------------|
| `alb_dns_name` | Load balancer DNS for accessing the backend |
| `ecr_repository_url` | ECR repository URL for pushing Docker images |
| `rds_endpoint` | PostgreSQL database endpoint |
| `ecs_cluster_name` | ECS cluster name |
| `ecs_service_name` | ECS service name |
| `vpc_id` | VPC identifier |
| `db_credentials_secret_arn` | Secrets Manager ARN for database credentials |
| `app_secrets_arn` | Secrets Manager ARN for application secrets |

## Cost Optimization

**Development Environment:**
- Estimated cost: ~$30-50/month
- Single NAT Gateway, db.t3.micro, minimal ECS tasks

**Staging Environment:**
- Estimated cost: ~$100-150/month
- Single NAT Gateway, db.t3.small, moderate ECS resources

**Production Environment:**
- Estimated cost: ~$300-500/month
- Multi-AZ setup, NAT per AZ, larger instances, auto-scaling

To reduce costs:
1. Stop non-production environments when not in use
2. Use Fargate Spot for dev/staging
3. Reduce RDS backup retention for dev
4. Use smaller instance classes for development

## Security Considerations

1. **Network Isolation**: ECS tasks and RDS are in private subnets with no direct internet access
2. **Secrets Management**: All sensitive data stored in AWS Secrets Manager, not in code
3. **Encryption**: RDS storage encryption enabled by default
4. **Security Groups**: Least-privilege access between components
5. **IAM Roles**: Task execution and task roles with minimal required permissions

## Troubleshooting

### ECS Tasks Failing to Start

Check CloudWatch logs:
```bash
aws logs tail /ecs/full-stack-fastapi-project-dev/backend --follow --region eu-west-1
```

Common issues:
- Image not found in ECR (push the image first)
- Secrets Manager permissions (check task execution role)
- Container health check failing (check application health endpoint)

### Cannot Pull from ECR

Ensure the task execution role has permissions to pull from ECR:
```bash
# The ecs_service module automatically grants these permissions
# Check the task execution role in IAM console
```

### Database Connection Issues

1. Verify security group rules allow ECS -> RDS on port 5432
2. Check database endpoint is correct
3. Verify credentials in Secrets Manager
4. Ensure ECS tasks are in the correct subnets

### Load Balancer Health Checks Failing

1. Verify the health check path `/api/health` is correct
2. Check container port mapping (80)
3. Review application logs for errors
4. Ensure security group allows ALB -> ECS traffic

## Cleanup

To destroy the infrastructure:

```bash
terraform destroy -var-file=environments/dev/terraform.tfvars
```

**Note**: This will delete all resources including the database. Ensure you have backups if needed.

## Next Steps

1. **Add HTTPS**: Configure ACM certificate and update ALB listener
2. **Custom Domain**: Set up Route53 for custom domain routing
3. **Monitoring**: Add CloudWatch alarms for CPU, memory, and errors
4. **CI/CD**: Integrate with GitHub Actions or similar for automated deployments
5. **Caching**: Add ElastiCache Redis for session/query caching
6. **CDN**: Add CloudFront for static asset distribution

## Naming Conventions

All resources follow a consistent naming pattern:

- **Hierarchical resources** (Secrets Manager, CloudWatch Logs): `env/project/service`
- **Flat resources** (EC2, RDS, ECS, ALB, etc.): `project-resource-name-env`

See [NAMING.md](NAMING.md) for complete naming convention documentation.

**Examples:**
```
# Hierarchical (env first in path)
dev/full-stack-fastapi-project/app/secrets
/ecs/dev/full-stack-fastapi-project/backend

# Flat (env last in name)
full-stack-fastapi-project-alb-dev
full-stack-fastapi-project-db-production
full-stack-fastapi-project-cluster-staging
full-stack-fastapi-project-backend-tg-dev
```

## Support

For issues or questions:
1. Check CloudWatch Logs for application errors
2. Review ECS service events
3. Verify Terraform outputs are correct
4. Check AWS console for service health

## License

This infrastructure code is part of the Full Stack FastAPI Project.
