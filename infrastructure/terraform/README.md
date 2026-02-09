# ECS Terraform Infrastructure

This directory contains Terraform infrastructure-as-code for deploying the Full Stack FastAPI application to AWS ECS on EC2 with Application Load Balancer, RDS PostgreSQL, and complete CI/CD integration.

## Architecture Overview

- **VPC**: Custom VPC with public and private subnets across 2 availability zones
- **ALB**: Application Load Balancer for HTTPS termination and routing
- **ECS on EC2**: Container orchestration with Auto Scaling Groups
- **RDS**: Managed PostgreSQL database (Multi-AZ in production)
- **ECR**: Private Docker registries for backend and frontend
- **CloudWatch**: Centralized logging and optional alarms
- **SSM Parameter Store**: Secure secrets management
- **Cloud Map**: Service discovery for internal DNS

## Directory Structure

```
infrastructure/terraform/
├── main.tf                  # Main orchestration file
├── variables.tf             # Variable definitions
├── outputs.tf               # Output definitions
├── versions.tf              # Provider versions and S3 backend
├── locals.tf                # Local values
├── data.tf                  # Data sources
├── ssm-parameters.tf        # SSM parameter definitions
├── modules/                 # Reusable modules
│   ├── networking/          # VPC, subnets, NAT
│   ├── security/            # Security groups, IAM roles
│   ├── database/            # RDS PostgreSQL
│   ├── ecr/                 # ECR repositories
│   ├── service-discovery/   # AWS Cloud Map
│   ├── monitoring/          # CloudWatch logs, alarms
│   ├── load-balancer/       # ALB, target groups
│   └── compute/             # ECS cluster, tasks, service
└── environments/            # Environment-specific configs
    ├── staging/
    │   ├── terraform.tfvars # Staging variables
    │   └── backend.hcl      # Staging state config
    └── production/
        ├── terraform.tfvars # Production variables
        └── backend.hcl      # Production state config
```

## Prerequisites

### 1. AWS Account Setup

- AWS account with appropriate permissions
- AWS CLI configured (`aws configure`)
- S3 bucket for Terraform state
- Domain registered (can be anywhere, not required to be in Route53)
- Route53 hosted zone (will be created automatically or use existing)

### 2. Local Tools

- [Terraform](https://www.terraform.io/downloads) >= 1.5.0
- [AWS CLI](https://aws.amazon.com/cli/) >= 2.0
- Docker (for building images)

### 3. Create S3 Backend Bucket

```bash
# Create S3 bucket for Terraform state
aws s3 mb s3://digico-fullstack-tfstate-bucket --region us-east-1

# Enable versioning
aws s3api put-bucket-versioning \
  --bucket digico-fullstack-tfstate-bucket \
  --versioning-configuration Status=Enabled

# Enable encryption
aws s3api put-bucket-encryption \
  --bucket digico-fullstack-tfstate-bucket \
  --server-side-encryption-configuration '{
    "Rules": [{
      "ApplyServerSideEncryptionByDefault": {
        "SSEAlgorithm": "AES256"
      }
    }]
  }'
```

### 4. Route53 Hosted Zone (Optional)

Terraform can automatically create a Route53 hosted zone or use an existing one.

**Option A: Use Existing Hosted Zone**
- Set `create_hosted_zone = false` in terraform.tfvars (default)
- Ensure hosted zone exists in Route53

**Option B: Create New Hosted Zone**
- Set `create_hosted_zone = true` in terraform.tfvars
- After terraform apply, update your domain registrar with the name servers from terraform output

## Initial Setup

### 1. Configure Environment Variables

Edit `environments/staging/terraform.tfvars`:

```hcl
# Update these values
aws_region         = "us-east-1"
domain             = "staging.example.com"
create_hosted_zone = false  # Set to true if you need Terraform to create the zone

# Generate secure secrets
secret_key                 = "GENERATE_WITH_PYTHON_COMMAND"
first_superuser_password  = "GENERATE_SECURE_PASSWORD"
```

Generate secure values:

```bash
# Generate SECRET_KEY
python -c "import secrets; print(secrets.token_urlsafe(32))"

# Generate secure password
python -c "import secrets; print(secrets.token_urlsafe(24))"
```

### 2. Initialize Terraform

```bash
cd infrastructure/terraform

# Initialize for staging
terraform init -backend-config=environments/staging/backend.hcl
```

### 3. Review the Plan

```bash
# Plan infrastructure changes
terraform plan -var-file=environments/staging/terraform.tfvars
```

### 4. Apply Infrastructure

```bash
# Apply changes (creates all infrastructure)
terraform apply -var-file=environments/staging/terraform.tfvars
```

This will create:
- Route53 hosted zone (if `create_hosted_zone = true`)
- ACM certificate with automatic DNS validation
- VPC with public/private subnets
- Security groups and IAM roles
- RDS PostgreSQL database
- ECR repositories
- ECS cluster with Auto Scaling
- Application Load Balancer
- Route53 DNS records (api, dashboard, adminer)
- CloudWatch log groups
- Service discovery namespace

**Note**: 
1. Certificate validation takes 5-15 minutes via DNS (fully automated)
2. Initial `terraform apply` will fail on ECS service creation because Docker images don't exist yet. This is expected. Push images to ECR first, then run `terraform apply` again.
3. If `create_hosted_zone = true`, update your domain registrar with the name servers from `terraform output route53_name_servers`

## Deploying Application Updates

### Manual Deployment

```bash
# 1. Build and push Docker images
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com

docker build -t ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/full-stack-fastapi-project-staging-backend:staging-abc1234 -f backend/Dockerfile .
docker push ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/full-stack-fastapi-project-staging-backend:staging-abc1234

docker build -t ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/full-stack-fastapi-project-staging-frontend:staging-abc1234 \
  --build-arg VITE_API_URL=https://api.staging.example.com \
  -f frontend/Dockerfile .
docker push ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/full-stack-fastapi-project-staging-frontend:staging-abc1234

# 2. Update infrastructure with new image tags
terraform apply \
  -var-file=environments/staging/terraform.tfvars \
  -var="backend_image_tag=staging-abc1234" \
  -var="frontend_image_tag=staging-abc1234"
```

### Automated Deployment (GitHub Actions)

The repository includes GitHub Actions workflows for automated deployment:

- **Staging**: Deploys on push to `master` branch
- **Production**: Deploys on release publish

See [GitHub Actions Setup](#github-actions-setup) below.

## GitHub Actions Setup

### Required Secrets

Configure these secrets in your GitHub repository (Settings → Secrets and variables → Actions):

**AWS Credentials**:
- `AWS_ACCESS_KEY_ID` - AWS access key
- `AWS_SECRET_ACCESS_KEY` - AWS secret key
- `AWS_REGION` - AWS region (e.g., `us-east-1`)
- `AWS_ACCOUNT_ID` - AWS account ID

**Domain Names**:
- `DOMAIN_STAGING` - Staging domain (e.g., `staging.example.com`)
- `DOMAIN_PRODUCTION` - Production domain (e.g., `example.com`)

### Workflows

1. **deploy-infrastructure.yml**: Validates and applies Terraform changes
2. **deploy-staging.yml**: Builds images and deploys to staging
3. **deploy-production.yml**: Builds images and deploys to production

## DNS Configuration

DNS is automatically configured by Terraform! The following records are created automatically:

- `api.{domain}` → ALB (alias record)
- `dashboard.{domain}` → ALB (alias record)
- `adminer.{domain}` → ALB (alias record)

### If You Created a New Hosted Zone

If you set `create_hosted_zone = true`, you need to update your domain registrar:

```bash
# Get name servers
terraform output route53_name_servers

# Update your domain registrar (e.g., GoDaddy, Namecheap, etc.) 
# with these name servers
```

This is a one-time configuration at your domain registrar. After the name servers are updated (takes 24-48 hours to propagate), all DNS is managed by Terraform.

## Accessing Services

After deployment and DNS configuration:

- **Frontend**: https://dashboard.staging.example.com
- **Backend API**: https://api.staging.example.com
- **API Docs**: https://api.staging.example.com/docs
- **Adminer**: https://adminer.staging.example.com

## Monitoring and Logs

### CloudWatch Logs

View application logs:

```bash
# Backend logs
aws logs tail /ecs/full-stack-fastapi-project-staging/backend --follow

# Frontend logs
aws logs tail /ecs/full-stack-fastapi-project-staging/frontend --follow
```

### ECS Service Status

```bash
# Check ECS service
aws ecs describe-services \
  --cluster full-stack-fastapi-project-staging \
  --services full-stack-fastapi-project-staging-service
```

### Database Access

```bash
# Get RDS endpoint
terraform output rds_endpoint

# Connect using psql (from within VPC)
psql -h RDS_ENDPOINT -U postgres -d app
```

## Troubleshooting

### ECS Tasks Not Starting

1. Check CloudWatch logs for container errors
2. Verify ECR images exist and are tagged correctly
3. Check IAM role permissions for ECS task execution
4. Verify SSM parameters are created correctly

```bash
# List SSM parameters
aws ssm get-parameters-by-path \
  --path "/staging/full-stack-fastapi-project/" \
  --recursive
```

### ALB Health Checks Failing

1. Check security group rules (ALB → ECS)
2. Verify container port mappings (8000, 80, 8080)
3. Check health check endpoints:
   - Backend: `/api/v1/utils/health-check/`
   - Frontend: `/`
   - Adminer: `/`

### Database Connection Issues

1. Verify RDS security group allows connections from ECS
2. Check SSM parameter for `POSTGRES_PASSWORD`
3. Verify database endpoint in environment variables

## Scaling

### ECS Service Scaling

```bash
# Scale ECS service manually
aws ecs update-service \
  --cluster full-stack-fastapi-project-staging \
  --service full-stack-fastapi-project-staging-service \
  --desired-count 2
```

Or update `ecs_desired_count` in terraform.tfvars:

```hcl
ecs_desired_count = 2
```

### EC2 Auto Scaling

Managed automatically by ECS capacity provider. To adjust:

```hcl
# In terraform.tfvars
asg_min_size = 1
asg_max_size = 5
```

## Rollback

### Rollback to Previous Image

```bash
# Deploy with previous image tag
terraform apply \
  -var-file=environments/staging/terraform.tfvars \
  -var="backend_image_tag=staging-xyz7890" \
  -var="frontend_image_tag=staging-xyz7890"
```

### Rollback Infrastructure Changes

```bash
# Rollback Terraform state
terraform state pull > backup.tfstate
# ... make changes ...
terraform apply
```

## Destroying Infrastructure

**WARNING**: This will delete all resources including the database!

```bash
# Destroy staging environment
terraform destroy -var-file=environments/staging/terraform.tfvars

# Confirm with: yes
```

## Cost Optimization

### Staging Environment

- Single NAT Gateway (not per AZ)
- Single AZ RDS
- Smaller instance types (t3.small, db.t3.micro)
- 1-day backup retention

### Production Environment

- Multi-AZ RDS for high availability
- Larger instances (t3.medium, db.t3.small)
- 7-day backup retention
- CloudWatch Container Insights enabled

## Security Best Practices

1. **Secrets**: Never commit secrets to git. Use SSM Parameter Store
2. **IAM**: Follow principle of least privilege
3. **Network**: ECS tasks in private subnets, ALB in public subnets
4. **Encryption**: RDS and EBS volumes encrypted at rest
5. **HTTPS Only**: HTTP redirects to HTTPS at ALB
6. **Security Groups**: Restrictive ingress rules

## Support

For issues or questions:

1. Check CloudWatch logs
2. Review Terraform plan output
3. Consult AWS ECS documentation
4. Review module READMEs in `modules/` directories

## Additional Resources

- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [AWS ECS Documentation](https://docs.aws.amazon.com/ecs/)
- [Terraform Module Registry](https://registry.terraform.io/browse/modules)
