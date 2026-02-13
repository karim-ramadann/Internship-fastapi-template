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
terraform init -backend-config=environments/dev/backend.hcl
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

<!-- BEGIN_TF_DOCS -->


## Infrastructure Overview

This runtime infrastructure configuration deploys a complete AWS environment with:

- **Networking**: VPC with public/private/database subnets across 2 AZs
- **Compute**: ECS Fargate cluster with auto-scaling
- **Load Balancing**: Application Load Balancer with health checks
- **Database**: RDS PostgreSQL with automated backups and encryption
- **Container Registry**: ECR for Docker images
- **Security**: Security groups, IAM roles, secrets management
- **Monitoring**: CloudWatch logs for all services

## Environment Configuration

Each environment (dev, staging, production) has its own:
- Terraform state file in S3
- Variable configuration in `environments/{env}/terraform.tfvars`
- Independent deployment lifecycle

See [NAMING.md](NAMING.md) for resource naming conventions.

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.5.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 5.0 |
| <a name="requirement_random"></a> [random](#requirement\_random) | ~> 3.6 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | ~> 5.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_alb"></a> [alb](#module\_alb) | terraform-aws-modules/alb/aws | ~> 9.0 |
| <a name="module_alb_security_group"></a> [alb\_security\_group](#module\_alb\_security\_group) | terraform-aws-modules/security-group/aws | ~> 5.0 |
| <a name="module_database"></a> [database](#module\_database) | ../modules/database | n/a |
| <a name="module_ecr_backend"></a> [ecr\_backend](#module\_ecr\_backend) | ../modules/aws_ecr_repository | n/a |
| <a name="module_ecs_cluster"></a> [ecs\_cluster](#module\_ecs\_cluster) | ../modules/aws_ecs_cluster | n/a |
| <a name="module_ecs_security_group"></a> [ecs\_security\_group](#module\_ecs\_security\_group) | terraform-aws-modules/security-group/aws | ~> 5.0 |
| <a name="module_ecs_service_backend"></a> [ecs\_service\_backend](#module\_ecs\_service\_backend) | ../modules/aws_ecs_service | n/a |
| <a name="module_rds_security_group"></a> [rds\_security\_group](#module\_rds\_security\_group) | terraform-aws-modules/security-group/aws | ~> 5.0 |
| <a name="module_vpc"></a> [vpc](#module\_vpc) | ../modules/aws_vpc | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_secretsmanager_secret.app_secrets](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret) | resource |
| [aws_secretsmanager_secret_version.app_secrets](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret_version) | resource |
| [aws_security_group_rule.alb_to_ecs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.ecs_to_rds](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_aws_region"></a> [aws\_region](#input\_aws\_region) | AWS region for all resources | `string` | n/a | yes |
| <a name="input_backend_cors_origins"></a> [backend\_cors\_origins](#input\_backend\_cors\_origins) | Allowed CORS origins (comma-separated) | `string` | n/a | yes |
| <a name="input_domain"></a> [domain](#input\_domain) | Base domain for the application | `string` | n/a | yes |
| <a name="input_emails_from_email"></a> [emails\_from\_email](#input\_emails\_from\_email) | Email address to send from | `string` | n/a | yes |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment name (dev, staging, production) | `string` | n/a | yes |
| <a name="input_first_superuser"></a> [first\_superuser](#input\_first\_superuser) | Email for first superuser | `string` | n/a | yes |
| <a name="input_first_superuser_password"></a> [first\_superuser\_password](#input\_first\_superuser\_password) | Password for first superuser | `string` | n/a | yes |
| <a name="input_frontend_host"></a> [frontend\_host](#input\_frontend\_host) | Frontend URL for email links | `string` | n/a | yes |
| <a name="input_secret_key"></a> [secret\_key](#input\_secret\_key) | Backend secret key for JWT tokens | `string` | n/a | yes |
| <a name="input_autoscaling_max_capacity"></a> [autoscaling\_max\_capacity](#input\_autoscaling\_max\_capacity) | Maximum number of tasks for auto-scaling | `number` | `10` | no |
| <a name="input_autoscaling_min_capacity"></a> [autoscaling\_min\_capacity](#input\_autoscaling\_min\_capacity) | Minimum number of tasks for auto-scaling | `number` | `1` | no |
| <a name="input_backend_image_tag"></a> [backend\_image\_tag](#input\_backend\_image\_tag) | Docker image tag for backend (e.g., latest, v1.0.0) | `string` | `"latest"` | no |
| <a name="input_common_tags"></a> [common\_tags](#input\_common\_tags) | Common tags to apply to all resources | `map(string)` | `{}` | no |
| <a name="input_db_name"></a> [db\_name](#input\_db\_name) | Database name | `string` | `"app"` | no |
| <a name="input_db_username"></a> [db\_username](#input\_db\_username) | Database master username | `string` | `"postgres"` | no |
| <a name="input_ecr_repository_name"></a> [ecr\_repository\_name](#input\_ecr\_repository\_name) | Name for the ECR repository | `string` | `"backend"` | no |
| <a name="input_ecs_desired_count"></a> [ecs\_desired\_count](#input\_ecs\_desired\_count) | Desired number of ECS tasks | `number` | `1` | no |
| <a name="input_enable_autoscaling"></a> [enable\_autoscaling](#input\_enable\_autoscaling) | Enable auto-scaling for ECS service | `bool` | `false` | no |
| <a name="input_one_nat_gateway_per_az"></a> [one\_nat\_gateway\_per\_az](#input\_one\_nat\_gateway\_per\_az) | Create one NAT Gateway per availability zone (recommended for production) | `bool` | `false` | no |
| <a name="input_project"></a> [project](#input\_project) | Project name | `string` | `"full-stack-fastapi-project"` | no |
| <a name="input_rds_allocated_storage"></a> [rds\_allocated\_storage](#input\_rds\_allocated\_storage) | RDS allocated storage in GB | `number` | `20` | no |
| <a name="input_rds_backup_retention_days"></a> [rds\_backup\_retention\_days](#input\_rds\_backup\_retention\_days) | RDS backup retention period in days | `number` | `7` | no |
| <a name="input_rds_instance_class"></a> [rds\_instance\_class](#input\_rds\_instance\_class) | RDS instance class | `string` | `"db.t3.micro"` | no |
| <a name="input_rds_multi_az"></a> [rds\_multi\_az](#input\_rds\_multi\_az) | Enable Multi-AZ deployment for RDS | `bool` | `false` | no |
| <a name="input_sentry_dsn"></a> [sentry\_dsn](#input\_sentry\_dsn) | Sentry DSN for error tracking | `string` | `""` | no |
| <a name="input_single_nat_gateway"></a> [single\_nat\_gateway](#input\_single\_nat\_gateway) | Use a single NAT Gateway for all private subnets (cost-effective for dev/staging) | `bool` | `true` | no |
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
| <a name="output_alb_arn"></a> [alb\_arn](#output\_alb\_arn) | ARN of the Application Load Balancer |
| <a name="output_alb_dns_name"></a> [alb\_dns\_name](#output\_alb\_dns\_name) | DNS name of the Application Load Balancer |
| <a name="output_alb_security_group_id"></a> [alb\_security\_group\_id](#output\_alb\_security\_group\_id) | ID of the ALB security group |
| <a name="output_alb_target_group_arn"></a> [alb\_target\_group\_arn](#output\_alb\_target\_group\_arn) | ARN of the backend target group |
| <a name="output_alb_zone_id"></a> [alb\_zone\_id](#output\_alb\_zone\_id) | Zone ID of the Application Load Balancer |
| <a name="output_app_secrets_arn"></a> [app\_secrets\_arn](#output\_app\_secrets\_arn) | ARN of the Secrets Manager secret containing application secrets |
| <a name="output_aws_region"></a> [aws\_region](#output\_aws\_region) | AWS region |
| <a name="output_database_subnet_ids"></a> [database\_subnet\_ids](#output\_database\_subnet\_ids) | IDs of the database subnets |
| <a name="output_db_credentials_secret_arn"></a> [db\_credentials\_secret\_arn](#output\_db\_credentials\_secret\_arn) | ARN of the Secrets Manager secret containing database credentials |
| <a name="output_deployment_instructions"></a> [deployment\_instructions](#output\_deployment\_instructions) | Instructions for deploying the application |
| <a name="output_ecr_repository_arn"></a> [ecr\_repository\_arn](#output\_ecr\_repository\_arn) | ARN of the ECR repository |
| <a name="output_ecr_repository_url"></a> [ecr\_repository\_url](#output\_ecr\_repository\_url) | URL of the ECR repository for backend images |
| <a name="output_ecs_cluster_arn"></a> [ecs\_cluster\_arn](#output\_ecs\_cluster\_arn) | ARN of the ECS cluster |
| <a name="output_ecs_cluster_id"></a> [ecs\_cluster\_id](#output\_ecs\_cluster\_id) | ID of the ECS cluster |
| <a name="output_ecs_cluster_name"></a> [ecs\_cluster\_name](#output\_ecs\_cluster\_name) | Name of the ECS cluster |
| <a name="output_ecs_security_group_id"></a> [ecs\_security\_group\_id](#output\_ecs\_security\_group\_id) | ID of the ECS security group |
| <a name="output_ecs_service_id"></a> [ecs\_service\_id](#output\_ecs\_service\_id) | ARN of the ECS service |
| <a name="output_ecs_service_name"></a> [ecs\_service\_name](#output\_ecs\_service\_name) | Name of the ECS service |
| <a name="output_ecs_task_definition_arn"></a> [ecs\_task\_definition\_arn](#output\_ecs\_task\_definition\_arn) | ARN of the task definition |
| <a name="output_ecs_task_execution_role_arn"></a> [ecs\_task\_execution\_role\_arn](#output\_ecs\_task\_execution\_role\_arn) | ARN of the task execution IAM role |
| <a name="output_ecs_task_role_arn"></a> [ecs\_task\_role\_arn](#output\_ecs\_task\_role\_arn) | ARN of the task IAM role |
| <a name="output_environment"></a> [environment](#output\_environment) | Current environment name |
| <a name="output_private_subnet_ids"></a> [private\_subnet\_ids](#output\_private\_subnet\_ids) | IDs of the private subnets |
| <a name="output_public_subnet_ids"></a> [public\_subnet\_ids](#output\_public\_subnet\_ids) | IDs of the public subnets |
| <a name="output_rds_address"></a> [rds\_address](#output\_rds\_address) | RDS instance address (host only) |
| <a name="output_rds_database_name"></a> [rds\_database\_name](#output\_rds\_database\_name) | Name of the database |
| <a name="output_rds_endpoint"></a> [rds\_endpoint](#output\_rds\_endpoint) | RDS instance endpoint (host:port) |
| <a name="output_rds_instance_id"></a> [rds\_instance\_id](#output\_rds\_instance\_id) | Identifier of the RDS instance |
| <a name="output_rds_port"></a> [rds\_port](#output\_rds\_port) | RDS instance port |
| <a name="output_rds_security_group_id"></a> [rds\_security\_group\_id](#output\_rds\_security\_group\_id) | ID of the RDS security group |
| <a name="output_vpc_cidr_block"></a> [vpc\_cidr\_block](#output\_vpc\_cidr\_block) | CIDR block of the VPC |
| <a name="output_vpc_id"></a> [vpc\_id](#output\_vpc\_id) | ID of the VPC |
<!-- END_TF_DOCS -->