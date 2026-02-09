# Quick Start Guide

This is a quick reference for getting started with the ECS Terraform infrastructure. For comprehensive documentation, see [README.md](./README.md).

## Implementation Status

✅ **COMPLETED** - All Terraform modules and configuration files have been implemented:

- **8 Terraform modules**: networking, security, database, ECR, service-discovery, monitoring, load-balancer, compute
- **Root configuration**: main.tf, variables.tf, outputs.tf, versions.tf, locals.tf, data.tf, ssm-parameters.tf
- **Environment configs**: staging and production tfvars + backend.hcl files
- **GitHub Actions**: Updated workflows for infrastructure and application deployment (staging + production)
- **Documentation**: Comprehensive README, updated root README and deployment.md

## Next Steps (Manual Tasks Required)

### 1. AWS Prerequisites Setup

**Task**: Create AWS resources that Terraform requires as prerequisites

```bash
# Create S3 bucket for Terraform state
aws s3 mb s3://digico-fullstack-tfstate-bucket --region us-east-1
aws s3api put-bucket-versioning \
  --bucket digico-fullstack-tfstate-bucket \
  --versioning-configuration Status=Enabled
```

**That's it!** ACM certificates and Route53 records are now created automatically by Terraform.

**Note**: If you don't have a Route53 hosted zone yet, set `create_hosted_zone = true` in terraform.tfvars. After terraform apply, update your domain registrar with the name servers from terraform output.

### 2. Configure GitHub Secrets

**Task**: Add required secrets to GitHub repository (Settings → Secrets and variables → Actions)

**Required Secrets**:
- `AWS_ACCESS_KEY_ID` - AWS access key with appropriate permissions
- `AWS_SECRET_ACCESS_KEY` - AWS secret access key
- `AWS_REGION` - AWS region (e.g., `us-east-1`)
- `AWS_ACCOUNT_ID` - Your AWS account ID
- `DOMAIN_STAGING` - Staging domain (e.g., `staging.example.com`)
- `DOMAIN_PRODUCTION` - Production domain (e.g., `example.com`)

### 3. Update Environment Variables

**Task**: Edit `environments/staging/terraform.tfvars` and `environments/production/terraform.tfvars`

Update these values:
- `aws_region` - Your preferred AWS region
- `domain` - Your actual domain
- `create_hosted_zone` - Set to `true` if you need a new hosted zone, `false` to use existing
- `secret_key` - Generate with: `python -c "import secrets; print(secrets.token_urlsafe(32))"`
- `first_superuser_password` - Generate secure password
- `backend_cors_origins` - Your actual frontend URLs
- SMTP settings (if using email)

### 4. Initialize and Validate Terraform

**Task**: Initialize Terraform and validate configuration

```bash
cd infrastructure/terraform

# Initialize with staging backend
terraform init -backend-config=environments/staging/backend.hcl

# Validate configuration
terraform validate

# Plan infrastructure (review changes)
terraform plan -var-file=environments/staging/terraform.tfvars
```

### 5. Deploy Staging Infrastructure

**Task**: Apply Terraform configuration to create all AWS resources

```bash
# Apply configuration
terraform apply -var-file=environments/staging/terraform.tfvars

# Note: Initial apply will partially fail on ECS service because
# Docker images don't exist yet. This is expected.
```

**Expected resources created**:
- Route53 hosted zone (if `create_hosted_zone = true`)
- ACM certificate with automatic DNS validation (5-15 mins)
- VPC with public/private subnets
- Security groups and IAM roles
- RDS PostgreSQL database
- ECR repositories (backend + frontend)
- ECS cluster and capacity provider
- Application Load Balancer + target groups
- Route53 DNS records (api, dashboard, adminer)
- CloudWatch log groups
- Service discovery namespace
- SSM parameters

**Important**: Certificate validation happens automatically via DNS. This takes 5-15 minutes. Terraform will wait for validation to complete.

### 6. Build and Push Initial Docker Images

**Task**: Push first images to ECR to complete ECS service deployment

```bash
# Login to ECR
aws ecr get-login-password --region us-east-1 | \
  docker login --username AWS --password-stdin ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com

# Build and push backend
docker build -t ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/full-stack-fastapi-project-staging-backend:staging-initial \
  -f backend/Dockerfile .
docker push ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/full-stack-fastapi-project-staging-backend:staging-initial

# Build and push frontend
docker build -t ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/full-stack-fastapi-project-staging-frontend:staging-initial \
  --build-arg VITE_API_URL=https://api.staging.example.com \
  -f frontend/Dockerfile .
docker push ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/full-stack-fastapi-project-staging-frontend:staging-initial

# Re-run terraform apply with image tags
cd infrastructure/terraform
terraform apply \
  -var-file=environments/staging/terraform.tfvars \
  -var="backend_image_tag=staging-initial" \
  -var="frontend_image_tag=staging-initial"
```

### 7. Configure DNS (Only if you created a new hosted zone)

**Task**: Update domain registrar with Route53 name servers (one-time setup)

```bash
# Get name servers (only needed if create_hosted_zone = true)
cd infrastructure/terraform
terraform output route53_name_servers

# Update your domain registrar (e.g., GoDaddy, Namecheap, etc.) with these name servers
# This allows Route53 to manage DNS for your domain
```

**Note**: DNS records for api, dashboard, and adminer are created automatically by Terraform. No manual DNS configuration needed!

### 8. Test Staging Deployment

**Task**: Verify all services are running correctly

- **Frontend**: https://dashboard.staging.example.com
- **Backend API**: https://api.staging.example.com
- **API Docs**: https://api.staging.example.com/docs
- **Adminer**: https://adminer.staging.example.com

Check ECS service status:
```bash
aws ecs describe-services \
  --cluster full-stack-fastapi-project-staging \
  --services full-stack-fastapi-project-staging-service
```

View logs:
```bash
aws logs tail /ecs/full-stack-fastapi-project-staging/backend --follow
```

### 9. Deploy Production (After Staging Validation)

**Task**: Repeat steps 4-8 for production environment

Replace `staging` with `production` in all commands and use `environments/production/terraform.tfvars`.

**IMPORTANT**: Production deployment requires GitHub environment approval if configured.

### 10. Enable CI/CD

**Task**: Test automated deployments

After manual deployment is successful, test GitHub Actions:

1. Push code to `master` branch → triggers staging deployment
2. Create a release → triggers production deployment

Monitor GitHub Actions workflows:
- `.github/workflows/deploy-infrastructure.yml`
- `.github/workflows/deploy-staging.yml`
- `.github/workflows/deploy-production.yml`

## Architecture Highlights

- **No Infrastructure Drift**: All deployments via `terraform apply` with image tags as variables
- **Multi-Container ECS Task**: prestart, backend, frontend, adminer in single task
- **Auto Scaling**: ECS capacity provider manages EC2 auto scaling
- **Secrets Management**: SSM Parameter Store (SecureString for passwords)
- **Centralized Logging**: CloudWatch logs for all containers
- **Service Discovery**: AWS Cloud Map for internal DNS
- **HTTPS Only**: ALB handles SSL/TLS, HTTP redirects to HTTPS
- **Environment Isolation**: Separate VPCs, databases, ECR repos per environment

## Troubleshooting

### Common Issues

1. **Terraform init fails**: Ensure S3 bucket exists and AWS credentials are configured
2. **Certificate validation pending**: Add DNS CNAME records from ACM console
3. **ECS tasks not starting**: Check CloudWatch logs and IAM permissions
4. **ALB health checks failing**: Verify security group rules and container health check endpoints
5. **Database connection errors**: Check RDS security group and SSM parameters

For detailed troubleshooting, see [README.md](./README.md).

## Getting Help

- Review [README.md](./README.md) for comprehensive documentation
- Check CloudWatch logs for application errors
- Review Terraform plan output for infrastructure changes
- Consult [AWS ECS Documentation](https://docs.aws.amazon.com/ecs/)

## Cost Estimates

### Staging Environment
- **EC2**: ~$15-20/month (t3.small)
- **RDS**: ~$15/month (db.t3.micro single-AZ)
- **ALB**: ~$20/month
- **NAT Gateway**: ~$32/month (single)
- **Data Transfer**: Variable
- **Total**: ~$80-90/month

### Production Environment (estimated)
- **EC2**: ~$30-40/month (t3.medium)
- **RDS**: ~$50/month (db.t3.small multi-AZ)
- **ALB**: ~$20/month
- **NAT Gateway**: ~$64/month (2 AZs)
- **Data Transfer**: Variable
- **Total**: ~$160-180/month (base cost, scales with usage)

**Note**: Actual costs depend on traffic, data transfer, and scaling behavior.
