# ECS Terraform Infrastructure

This directory contains Terraform infrastructure-as-code for deploying the Full Stack FastAPI application to AWS ECS on EC2 with Application Load Balancer, RDS PostgreSQL, serverless data plane, and complete CI/CD integration.

## Architecture Overview

### Core Infrastructure
- **VPC**: Custom VPC with public and private subnets across 2 availability zones
- **ALB**: Application Load Balancer for HTTPS termination and host-based routing
- **ECS on EC2**: Container orchestration with Auto Scaling Groups and capacity providers
- **RDS**: Managed PostgreSQL database (Multi-AZ in production)
- **ECR**: Private Docker registries for backend, frontend, and Lambda functions
- **CloudWatch**: Centralized logging and optional alarms
- **SSM Parameter Store**: Secure secrets management
- **Cloud Map**: Service discovery for internal DNS

### Serverless Data Plane
- **EventBridge**: Custom event bus for asynchronous data processing
- **Step Functions**: Workflow orchestration for complex data pipelines
- **Lambda**: Event-driven compute for data processing tasks

## Directory Structure

```
infrastructure/terraform/
├── Core Configuration
│   ├── providers.tf          # Provider and required_providers configuration
│   ├── backend.tf             # S3 backend configuration
│   ├── datasources.tf         # AWS data sources (account, region, AZs)
│   ├── locals.tf              # Shared locals (naming, tagging)
│   ├── variables.tf           # All input variables
│   ├── outputs.tf             # All outputs
│   └── ssm-parameters.tf      # SSM Parameter Store secrets
│
├── Domain-Specific Business Logic (split by concern)
│   ├── networking.tf          # VPC, DNS, ALB, target groups, listeners, routing
│   ├── security.tf            # Security groups and IAM roles
│   ├── data.tf                # RDS, ECR, Service Discovery
│   ├── compute.tf             # ECS cluster, task definitions, services
│   └── observability.tf       # CloudWatch logs and alarms
│
├── Reusable Modules (thin wrappers around terraform-aws-modules)
│   ├── networking/            # VPC wrapper
│   ├── security/              # Security groups and IAM roles
│   ├── database/              # RDS PostgreSQL wrapper
│   ├── ecr/                   # ECR repositories
│   ├── service-discovery/     # AWS Cloud Map wrapper
│   ├── monitoring/            # CloudWatch wrapper
│   ├── acm/                   # ACM certificate wrapper
│   ├── route53/               # Route53 wrapper
│   ├── load-balancer/         # ALB wrapper (thin - no target groups)
│   ├── compute/               # ECS cluster wrapper (infrastructure only)
│   ├── lambda/                # Lambda function wrapper
│   ├── step-functions/        # Step Functions wrapper
│   └── eventbridge/           # EventBridge wrapper
│
├── Environment Configuration
│   └── environments/
│       ├── staging/
│       │   ├── terraform.tfvars # Staging variables
│       │   └── backend.hcl      # Staging state config
│       └── production/
│           ├── terraform.tfvars # Production variables
│           └── backend.hcl      # Production state config
│
├── Documentation
│   ├── README.md                            # This file
│   ├── .terraform-docs.yml                  # Root terraform-docs config
│   ├── .terraform-docs-module.yml           # Module terraform-docs template
│   ├── ROOT_REFACTORING_SUMMARY.md          # Root module refactoring details
│   ├── ROOT_STRUCTURE_COMPARISON.md         # Before/after comparison
│   ├── COMPUTE_MODULE_REFACTORING.md        # Compute refactoring details
│   ├── COMPUTE_REFACTORING_COMPLETE.md      # Compute summary
│   └── REFACTORING_PROGRESS.md              # Overall progress tracking
│
└── Build Tools
    └── Makefile                  # Common Terraform operations
```

## Architecture Principles

This infrastructure follows HashiCorp's Terraform best practices:

1. **Thin Wrapper Modules**: Modules wrap `terraform-aws-modules` and add only org-wide standards (naming, tagging)
2. **Business Logic in Root**: Application-specific configuration stays in root domain files
3. **Domain-Driven Organization**: Root split by concern (networking, compute, data) not by resource type
4. **Environment via tfvars**: All environment differences driven by variables, not code duplication
5. **Reusable Modules**: Modules work across different projects and use cases

See `.cursor/rules/terraform.mdc` for detailed standards.

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
- [terraform-docs](https://terraform-docs.io/) (optional, for documentation generation)
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
- Application Load Balancer with target groups and routing rules
- Route53 DNS records (api, dashboard, adminer)
- CloudWatch log groups
- Service discovery namespace

**Note**: 
1. Certificate validation takes 5-15 minutes via DNS (fully automated)
2. Initial `terraform apply` will fail on ECS service creation because Docker images don't exist yet. This is expected. Push images to ECR first, then run `terraform apply` again.
3. If `create_hosted_zone = true`, update your domain registrar with the name servers from `terraform output route53_name_servers`

## Common Operations

### Using the Makefile

The Makefile provides convenient shortcuts for common operations:

```bash
# Initialize Terraform
make init ENV=staging

# Format Terraform files
make fmt

# Validate configuration
make validate

# Plan changes
make plan ENV=staging

# Apply changes
make apply ENV=staging

# Generate documentation (requires terraform-docs)
make docs

# Clean up
make clean
```

### Manual Commands

```bash
# Format all files
terraform fmt -recursive

# Validate configuration
terraform validate

# Plan with specific environment
terraform plan -var-file=environments/staging/terraform.tfvars

# Apply with specific environment
terraform apply -var-file=environments/staging/terraform.tfvars

# Generate documentation for root
terraform-docs markdown table --output-file README.md --output-mode inject .

# Generate documentation for all modules
for dir in modules/*/; do
  terraform-docs markdown table --output-file README.md --output-mode inject "$dir"
done
```

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

# Prestart logs (database migrations)
aws logs tail /ecs/full-stack-fastapi-project-staging/prestart --follow
```

### ECS Service Status

```bash
# Check ECS cluster
aws ecs list-services --cluster full-stack-fastapi-project-staging

# Check service details
aws ecs describe-services \
  --cluster full-stack-fastapi-project-staging \
  --services full-stack-fastapi-project-staging-service

# Check running tasks
aws ecs list-tasks \
  --cluster full-stack-fastapi-project-staging \
  --service-name full-stack-fastapi-project-staging-service
```

### Database Access

```bash
# Get RDS endpoint
terraform output rds_endpoint

# Connect using psql (from within VPC or through bastion)
psql -h RDS_ENDPOINT -U postgres -d app
```

## Module Documentation

Each module has its own README generated by terraform-docs. To view:

```bash
# List all module READMEs
ls -la modules/*/README.md

# Read a specific module's documentation
cat modules/compute/README.md
```

To regenerate documentation:

```bash
make docs
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

# Check ECS task stopped reasons
aws ecs describe-tasks \
  --cluster full-stack-fastapi-project-staging \
  --tasks TASK_ID
```

### ALB Health Checks Failing

1. Check security group rules (ALB → ECS)
2. Verify container port mappings (8000, 80, 8080)
3. Check health check endpoints:
   - Backend: `/api/v1/utils/health-check/`
   - Frontend: `/`
   - Adminer: `/`

```bash
# Check target group health
aws elbv2 describe-target-health \
  --target-group-arn TARGET_GROUP_ARN
```

### Database Connection Issues

1. Verify RDS security group allows connections from ECS
2. Check SSM parameter for `POSTGRES_PASSWORD`
3. Verify database endpoint in environment variables
4. Check database is in `available` state

```bash
# Check RDS status
aws rds describe-db-instances \
  --db-instance-identifier full-stack-fastapi-project-staging
```

### Certificate Validation Issues

1. Ensure Route53 hosted zone is configured correctly
2. Wait 5-15 minutes for DNS propagation
3. Check ACM certificate status

```bash
# Check certificate status
aws acm describe-certificate --certificate-arn CERTIFICATE_ARN
```

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

**Note**: The ECS service has `lifecycle { ignore_changes = [desired_count] }` to prevent Terraform from overwriting manual scaling.

### EC2 Auto Scaling

Managed automatically by ECS capacity provider based on cluster utilization. The ASG sizing is environment-specific:

**Staging:**
- Min: 1, Max: 3, Desired: 1

**Production:**
- Min: 2, Max: 10, Desired: 2

These are configured in `compute.tf` based on the environment variable.

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
# View Terraform state history
terraform state list

# Pull specific version from S3 bucket versioning
aws s3api list-object-versions \
  --bucket digico-fullstack-tfstate-bucket \
  --prefix staging/terraform.tfstate

# Restore previous version if needed
# (This should be done carefully!)
```

## Destroying Infrastructure

**WARNING**: This will delete all resources including the database!

```bash
# Destroy staging environment
terraform destroy -var-file=environments/staging/terraform.tfvars

# Confirm with: yes
```

**Note**: Some resources may need manual cleanup:
- S3 backend bucket (contains state)
- ECR images (if repositories have `force_delete = false`)
- CloudWatch log groups (if retention is set)

## Cost Optimization

### Staging Environment

The infrastructure automatically configures cost-optimized settings for staging:

- ✅ Single NAT Gateway (not per AZ)
- ✅ Single AZ RDS (`rds_multi_az = false`)
- ✅ Smaller instance types (`t3.small`, `db.t3.micro`)
- ✅ 1-day backup retention
- ✅ ASG: 1-3 instances
- ✅ Container Insights disabled

### Production Environment

Production gets high-availability configuration:

- ✅ NAT Gateway per AZ for redundancy
- ✅ Multi-AZ RDS (`rds_multi_az = true`)
- ✅ Larger instances (`t3.medium`, `db.t3.small`)
- ✅ 7-day backup retention
- ✅ ASG: 2-10 instances
- ✅ Container Insights enabled
- ✅ ALB deletion protection enabled

These settings are configured automatically based on the `environment` variable in `networking.tf` and `compute.tf`.

## Security Best Practices

1. **Secrets Management**
   - Never commit secrets to git
   - Use SSM Parameter Store for all sensitive values
   - Secrets are passed to containers via ECS task definition

2. **IAM Roles**
   - Principle of least privilege
   - Separate task execution role (pull images, write logs) and task role (application permissions)
   - See `modules/security/` for role definitions

3. **Network Security**
   - ECS tasks in private subnets (no internet access)
   - ALB in public subnets
   - NAT Gateway for outbound traffic from private subnets
   - Security groups enforce least-privilege access

4. **Data Encryption**
   - RDS encrypted at rest (KMS)
   - EBS volumes encrypted
   - S3 backend encrypted
   - HTTPS enforced (HTTP redirects to HTTPS)

5. **HTTPS/TLS**
   - ACM certificate with automatic renewal
   - TLS 1.3 policy on ALB
   - HTTP automatically redirects to HTTPS

6. **Container Security**
   - IMDSv2 required on EC2 instances
   - Regular image updates via CI/CD
   - Non-root containers (where possible)

## Infrastructure Refactoring Notes

This infrastructure has been refactored to follow Terraform best practices. Key improvements:

1. **Root Module Split by Domain** - Instead of a monolithic `main.tf`, the root is organized by domain:
   - `networking.tf` - VPC, DNS, ALB, routing
   - `compute.tf` - ECS cluster, tasks, services
   - `data.tf` - RDS, ECR, persistence
   - `security.tf` - IAM, security groups
   - `observability.tf` - CloudWatch

2. **Thin Wrapper Modules** - Modules are thin wrappers around community modules:
   - Only add org-wide standards (naming, tagging)
   - No business logic in modules
   - Business logic (task definitions, routing rules) in root

3. **Environment Logic in Root** - Environment-specific decisions (production vs staging) in root files:
   ```hcl
   # Example from compute.tf
   asg_min_size = var.environment == "production" ? 2 : 1
   ```

4. **Reusable Modules** - Modules work for different applications:
   - `modules/compute/` can be used for any ECS EC2 cluster
   - `modules/lambda/` can be used for any Lambda function
   - Application-specific configuration stays in root

See documentation files for details:
- `ROOT_REFACTORING_SUMMARY.md` - Root module changes
- `ROOT_STRUCTURE_COMPARISON.md` - Before/after comparison
- `COMPUTE_MODULE_REFACTORING.md` - Compute module changes
- `REFACTORING_PROGRESS.md` - Overall progress

## Support

For issues or questions:

1. Check CloudWatch logs for application errors
2. Review Terraform plan output for infrastructure changes
3. Consult module READMEs in `modules/` directories
4. Check security group rules and IAM policies
5. Verify SSM parameters are set correctly

## Additional Resources

- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [terraform-aws-modules](https://registry.terraform.io/namespaces/terraform-aws-modules) - Community modules
- [AWS ECS Documentation](https://docs.aws.amazon.com/ecs/)
- [AWS ECS Best Practices](https://docs.aws.amazon.com/AmazonECS/latest/bestpracticesguide/)
- [Terraform Best Practices](https://www.terraform-best-practices.com/)
- [HashiCorp Learn - Terraform](https://learn.hashicorp.com/terraform)

<!-- BEGIN_TF_DOCS -->


## Architecture

This Terraform configuration deploys a complete full-stack application infrastructure on AWS with:

- **Networking**: VPC with public/private subnets across multiple AZs
- **Compute**: ECS on EC2 with auto-scaling
- **Load Balancing**: Application Load Balancer with HTTPS
- **Database**: RDS PostgreSQL with automatic backups
- **Storage**: ECR for container images
- **DNS**: Route53 with automatic certificate validation
- **Monitoring**: CloudWatch logs and optional alarms
- **Security**: Security groups, IAM roles, encrypted storage

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.5.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 5.0 |
| <a name="requirement_random"></a> [random](#requirement\_random) | ~> 3.6 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 5.100.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_acm"></a> [acm](#module\_acm) | ./modules/acm | n/a |
| <a name="module_database"></a> [database](#module\_database) | ./modules/database | n/a |
| <a name="module_ecr"></a> [ecr](#module\_ecr) | ./modules/ecr | n/a |
| <a name="module_ecs_fargate"></a> [ecs\_fargate](#module\_ecs\_fargate) | ./modules/ecs-fargate | n/a |
| <a name="module_load_balancer"></a> [load\_balancer](#module\_load\_balancer) | ./modules/load-balancer | n/a |
| <a name="module_monitoring"></a> [monitoring](#module\_monitoring) | ./modules/monitoring | n/a |
| <a name="module_networking"></a> [networking](#module\_networking) | ./modules/networking | n/a |
| <a name="module_route53"></a> [route53](#module\_route53) | ./modules/route53 | n/a |
| <a name="module_security"></a> [security](#module\_security) | ./modules/security | n/a |
| <a name="module_service_discovery"></a> [service\_discovery](#module\_service\_discovery) | ./modules/service-discovery | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_security_group_rule.fargate_to_rds](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_ssm_parameter.first_superuser_password](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_parameter) | resource |
| [aws_ssm_parameter.postgres_password](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_parameter) | resource |
| [aws_ssm_parameter.secret_key](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_parameter) | resource |
| [aws_ssm_parameter.sentry_dsn](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_parameter) | resource |
| [aws_ssm_parameter.smtp_host](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_parameter) | resource |
| [aws_ssm_parameter.smtp_password](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_parameter) | resource |
| [aws_ssm_parameter.smtp_user](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_parameter) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_aws_region"></a> [aws\_region](#input\_aws\_region) | AWS region for all resources | `string` | n/a | yes |
| <a name="input_backend_cors_origins"></a> [backend\_cors\_origins](#input\_backend\_cors\_origins) | Allowed CORS origins (comma-separated) | `string` | n/a | yes |
| <a name="input_domain"></a> [domain](#input\_domain) | Base domain for the application | `string` | n/a | yes |
| <a name="input_emails_from_email"></a> [emails\_from\_email](#input\_emails\_from\_email) | Email address to send from | `string` | n/a | yes |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment name (staging, production) | `string` | n/a | yes |
| <a name="input_first_superuser"></a> [first\_superuser](#input\_first\_superuser) | Email for first superuser | `string` | n/a | yes |
| <a name="input_first_superuser_password"></a> [first\_superuser\_password](#input\_first\_superuser\_password) | Password for first superuser | `string` | n/a | yes |
| <a name="input_frontend_host"></a> [frontend\_host](#input\_frontend\_host) | Frontend URL for email links | `string` | n/a | yes |
| <a name="input_secret_key"></a> [secret\_key](#input\_secret\_key) | Secret key for JWT tokens | `string` | n/a | yes |
| <a name="input_backend_image_tag"></a> [backend\_image\_tag](#input\_backend\_image\_tag) | Docker image tag for backend (e.g., staging-abc1234) | `string` | `"latest"` | no |
| <a name="input_common_tags"></a> [common\_tags](#input\_common\_tags) | Common tags to apply to all resources | `map(string)` | `{}` | no |
| <a name="input_create_hosted_zone"></a> [create\_hosted\_zone](#input\_create\_hosted\_zone) | Whether to create a new Route53 hosted zone or use an existing one | `bool` | `false` | no |
| <a name="input_db_name"></a> [db\_name](#input\_db\_name) | Database name | `string` | `"app"` | no |
| <a name="input_db_username"></a> [db\_username](#input\_db\_username) | Database master username | `string` | `"postgres"` | no |
| <a name="input_ecs_desired_count"></a> [ecs\_desired\_count](#input\_ecs\_desired\_count) | Desired number of ECS tasks | `number` | `1` | no |
| <a name="input_enable_service_discovery"></a> [enable\_service\_discovery](#input\_enable\_service\_discovery) | Enable AWS Cloud Map service discovery for ECS services | `bool` | `true` | no |
| <a name="input_frontend_image_tag"></a> [frontend\_image\_tag](#input\_frontend\_image\_tag) | Docker image tag for frontend (e.g., staging-abc1234) | `string` | `"latest"` | no |
| <a name="input_project"></a> [project](#input\_project) | Project name | `string` | `"full-stack-fastapi-project"` | no |
| <a name="input_rds_allocated_storage"></a> [rds\_allocated\_storage](#input\_rds\_allocated\_storage) | RDS allocated storage in GB | `number` | `20` | no |
| <a name="input_rds_backup_retention_days"></a> [rds\_backup\_retention\_days](#input\_rds\_backup\_retention\_days) | RDS backup retention period in days | `number` | `7` | no |
| <a name="input_rds_instance_class"></a> [rds\_instance\_class](#input\_rds\_instance\_class) | RDS instance class | `string` | `"db.t3.micro"` | no |
| <a name="input_rds_multi_az"></a> [rds\_multi\_az](#input\_rds\_multi\_az) | Enable Multi-AZ deployment for RDS | `bool` | `false` | no |
| <a name="input_sentry_dsn"></a> [sentry\_dsn](#input\_sentry\_dsn) | Sentry DSN | `string` | `""` | no |
| <a name="input_smtp_host"></a> [smtp\_host](#input\_smtp\_host) | SMTP server host | `string` | `""` | no |
| <a name="input_smtp_password"></a> [smtp\_password](#input\_smtp\_password) | SMTP server password | `string` | `""` | no |
| <a name="input_smtp_port"></a> [smtp\_port](#input\_smtp\_port) | SMTP server port | `number` | `587` | no |
| <a name="input_smtp_ssl"></a> [smtp\_ssl](#input\_smtp\_ssl) | Enable SSL for SMTP | `bool` | `false` | no |
| <a name="input_smtp_tls"></a> [smtp\_tls](#input\_smtp\_tls) | Enable TLS for SMTP | `bool` | `true` | no |
| <a name="input_smtp_user"></a> [smtp\_user](#input\_smtp\_user) | SMTP server user | `string` | `""` | no |
| <a name="input_task_cpu"></a> [task\_cpu](#input\_task\_cpu) | CPU units for the Fargate task (256, 512, 1024, 2048, 4096) | `number` | `1024` | no |
| <a name="input_task_memory"></a> [task\_memory](#input\_task\_memory) | Memory (MiB) for the Fargate task | `number` | `2048` | no |
| <a name="input_vpc_cidr"></a> [vpc\_cidr](#input\_vpc\_cidr) | CIDR block for VPC | `string` | `"10.0.0.0/16"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_alb_dns_name"></a> [alb\_dns\_name](#output\_alb\_dns\_name) | DNS name of the ALB - use this for DNS CNAME records |
| <a name="output_alb_zone_id"></a> [alb\_zone\_id](#output\_alb\_zone\_id) | Zone ID of the ALB for Route53 alias records |
| <a name="output_application_urls"></a> [application\_urls](#output\_application\_urls) | URLs for accessing the application |
| <a name="output_certificate_arn"></a> [certificate\_arn](#output\_certificate\_arn) | ARN of the validated ACM certificate |
| <a name="output_cloudwatch_log_groups"></a> [cloudwatch\_log\_groups](#output\_cloudwatch\_log\_groups) | CloudWatch log group names |
| <a name="output_ecr_backend_repository_url"></a> [ecr\_backend\_repository\_url](#output\_ecr\_backend\_repository\_url) | URL of the backend ECR repository |
| <a name="output_ecr_frontend_repository_url"></a> [ecr\_frontend\_repository\_url](#output\_ecr\_frontend\_repository\_url) | URL of the frontend ECR repository |
| <a name="output_ecs_cluster_arn"></a> [ecs\_cluster\_arn](#output\_ecs\_cluster\_arn) | ARN of the ECS cluster |
| <a name="output_ecs_cluster_id"></a> [ecs\_cluster\_id](#output\_ecs\_cluster\_id) | ID of the ECS cluster |
| <a name="output_ecs_cluster_name"></a> [ecs\_cluster\_name](#output\_ecs\_cluster\_name) | Name of the ECS cluster |
| <a name="output_ecs_service_id"></a> [ecs\_service\_id](#output\_ecs\_service\_id) | ID of the ECS service |
| <a name="output_ecs_service_name"></a> [ecs\_service\_name](#output\_ecs\_service\_name) | Name of the ECS service |
| <a name="output_rds_endpoint"></a> [rds\_endpoint](#output\_rds\_endpoint) | RDS instance endpoint |
| <a name="output_route53_name_servers"></a> [route53\_name\_servers](#output\_route53\_name\_servers) | Name servers for the hosted zone (update your domain registrar) |
| <a name="output_route53_zone_id"></a> [route53\_zone\_id](#output\_route53\_zone\_id) | ID of the Route53 hosted zone |
| <a name="output_service_discovery_namespace"></a> [service\_discovery\_namespace](#output\_service\_discovery\_namespace) | Name of the Cloud Map namespace |
| <a name="output_task_definition_arn"></a> [task\_definition\_arn](#output\_task\_definition\_arn) | ARN of the task definition |
| <a name="output_vpc_id"></a> [vpc\_id](#output\_vpc\_id) | ID of the VPC |
<!-- END_TF_DOCS -->