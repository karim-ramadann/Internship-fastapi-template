# CloudFormation Infrastructure for AIPOS HORECA

This directory contains CloudFormation templates and deployment scripts for the AIPOS HORECA infrastructure on AWS.

## Structure

```
infrastructure-cf/
├── 01-network.yaml          # Stack 1: VPC, subnets, NAT Gateway, Security Groups
├── 02-database.yaml          # Stack 2: RDS PostgreSQL with TimescaleDB
├── 03-storage.yaml           # Stack 3: S3 buckets (documents, data lake, models)
├── 04-compute.yaml           # Stack 4: ECR, ECS Fargate, ALB, Task Definitions
├── 05-async.yaml             # Stack 5: SQS queues and Lambda roles (placeholders)
├── 06-monitoring.yaml        # Stack 6: CloudWatch dashboards and alarms
├── parameters/
│   ├── dev.json              # Development environment parameters
│   ├── staging.json           # Staging environment parameters
│   └── prod.json              # Production environment parameters
├── scripts/
│   ├── deploy-stack.sh       # Deploy a single CloudFormation stack
│   ├── deploy-all.sh         # Deploy all stacks in order
│   ├── validate-stack.sh     # Validate a CloudFormation template
│   ├── destroy-stack.sh      # Destroy a single stack
│   └── stack-status.sh        # Check stack deployment status
├── Makefile                  # Makefile targets for CI/CD
└── README.md                  # This file
```

## Stack Overview

### Stack 1: Network (`01-network.yaml`)
Creates the foundational networking infrastructure:
- VPC with public/private subnets across 3 availability zones
- Internet Gateway for public internet access
- NAT Gateway(s) for private subnet internet access (1 for dev, 3 for HA in staging/prod)
- Security Groups for ALB, ECS, RDS, and Lambda
- Route tables for proper traffic routing

**Dependencies:** None (foundation stack)

### Stack 2: Database (`02-database.yaml`)
Creates the RDS PostgreSQL database:
- RDS PostgreSQL 15+ instance
- TimescaleDB extension support (via parameter group)
- Automated backups (7-day retention)
- Multi-AZ deployment (staging/prod only)
- Database subnet group and parameter group

**Dependencies:** Stack 1 (Network)

### Stack 3: Storage (`03-storage.yaml`)
Creates S3 buckets for data storage:
- Documents bucket (invoices, receipts)
- Data lake bucket (analytics data)
- Shared models bucket (ML models, shared across environments)
- Versioning enabled
- Lifecycle policies (archive to Glacier after 90 days)

**Dependencies:** None (can be deployed independently)

### Stack 4: Compute (`04-compute.yaml`)
Creates the containerized compute infrastructure:
- ECR repositories for backend and frontend images
- ECS Fargate cluster
- Application Load Balancer with HTTPS (ACM certificate)
- ECS Task Definitions for backend (FastAPI) and frontend (React/Nginx)
- ECS Services with auto-scaling (min 2, max 10 tasks)
- CloudWatch Log Groups

**Dependencies:** Stack 1 (Network)

### Stack 5: Async (`05-async.yaml`)
Creates async processing infrastructure (placeholders):
- SQS standard queues:
  - `processing-queue`
  - `notification-queue`
  - `data-ingestion-queue`
- Lambda execution roles (no functions yet)

**Dependencies:** None (can be deployed independently)

### Stack 6: Monitoring (`06-monitoring.yaml`)
Creates monitoring and alerting infrastructure:
- CloudWatch dashboard with key metrics
- CloudWatch alarms for:
  - ECS CPU/Memory utilization
  - RDS connections and CPU
  - ALB 5xx errors and response time
- SNS topic for alert notifications

**Dependencies:** Stack 4 (Compute), Stack 2 (Database)

## Deployment Order

Stacks must be deployed in the following order due to dependencies:

1. **01-network** (foundation)
2. **02-database** (depends on network)
3. **03-storage** (independent)
4. **04-compute** (depends on network)
5. **05-async** (independent)
6. **06-monitoring** (depends on compute and database)

## Prerequisites

- AWS CLI installed and configured
- Appropriate AWS credentials with permissions to create CloudFormation stacks
- Make (for using Makefile targets)
- jq (optional, for JSON parsing in scripts)

## Quick Start

### Using Makefile (Recommended)

```bash
# Validate all templates
make validate ENV=dev

# Deploy all stacks
make deploy ENV=dev

# Deploy a specific stack
make deploy-stack STACK=01-network ENV=dev

# Check status of all stacks
make status ENV=dev

# View stack outputs
make outputs ENV=dev

# Destroy a specific stack (with confirmation)
make destroy-stack STACK=01-network ENV=dev
```

### Using Scripts Directly

```bash
# Validate a template
./scripts/validate-stack.sh 01-network.yaml dev

# Deploy a single stack
./scripts/deploy-stack.sh 01-network 01-network.yaml dev

# Deploy all stacks
./scripts/deploy-all.sh dev

# Check stack status
./scripts/stack-status.sh 01-network dev --outputs

# Destroy a stack
./scripts/destroy-stack.sh 01-network dev
```

## Parameter Files

Parameter files are located in the `parameters/` directory. Each environment has its own parameter file:

- `dev.json` - Development environment (cost-optimized, single NAT gateway)
- `staging.json` - Staging environment (3 NAT gateways, Multi-AZ database)
- `prod.json` - Production environment (3 NAT gateways, Multi-AZ database, larger instances)

### Important Parameters

Before deploying, ensure these parameters are set correctly in the parameter files:

- `DatabaseMasterPassword` - Must be changed from default (use AWS Secrets Manager in production)
- `CertificateArn` - ACM certificate ARN for HTTPS (required for compute stack)
- `DomainName` - Domain name for the application
- `AlertEmail` - Email address for CloudWatch alarms

## CI/CD Integration

The Makefile includes CI/CD-specific targets that can be used in GitHub Actions workflows:

```yaml
# Example GitHub Actions workflow
name: Deploy Infrastructure
on:
  push:
    branches: [develop, master]
    paths:
      - 'infrastructure-cf/**'

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: aws-actions/configure-aws-credentials@v4
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: us-east-1
      - run: make ci-validate ENV=dev

  deploy-dev:
    needs: validate
    if: github.ref == 'refs/heads/develop'
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: aws-actions/configure-aws-credentials@v4
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: us-east-1
      - run: make ci-deploy ENV=dev

  deploy-staging:
    needs: validate
    if: github.ref == 'refs/heads/master'
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: aws-actions/configure-aws-credentials@v4
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: us-east-1
      - run: make ci-deploy ENV=staging
```

## Makefile Targets

| Target | Description | Example |
|--------|-------------|---------|
| `help` | Show help message | `make help` |
| `validate` | Validate all templates | `make validate ENV=dev` |
| `validate-stack` | Validate specific stack | `make validate-stack STACK=01-network ENV=dev` |
| `deploy` | Deploy all stacks | `make deploy ENV=dev` |
| `deploy-stack` | Deploy specific stack | `make deploy-stack STACK=01-network ENV=dev` |
| `destroy` | Destroy all stacks | `make destroy ENV=dev` |
| `destroy-stack` | Destroy specific stack | `make destroy-stack STACK=01-network ENV=dev` |
| `status` | Show status of all stacks | `make status ENV=dev` |
| `status-stack` | Show status of specific stack | `make status-stack STACK=01-network ENV=dev` |
| `outputs` | Show outputs of all stacks | `make outputs ENV=dev` |
| `outputs-stack` | Show outputs of specific stack | `make outputs-stack STACK=01-network ENV=dev` |
| `ci-validate` | Validate (CI/CD, no prompts) | `make ci-validate ENV=dev` |
| `ci-deploy` | Deploy (CI/CD, no prompts) | `make ci-deploy ENV=dev` |
| `ci-deploy-stack` | Deploy stack (CI/CD, no prompts) | `make ci-deploy-stack STACK=01-network ENV=dev` |

## Stack Outputs

Each stack exports outputs that can be imported by dependent stacks:

### Network Stack Outputs
- `VpcId` - VPC ID
- `PublicSubnetIds` - List of public subnet IDs
- `PrivateSubnetIds` - List of private subnet IDs
- `ALBSecurityGroupId` - ALB security group ID
- `ECSSecurityGroupId` - ECS security group ID
- `RDSSecurityGroupId` - RDS security group ID

### Database Stack Outputs
- `DBInstanceIdentifier` - RDS instance identifier
- `DBEndpoint` - RDS endpoint address
- `DBPort` - RDS port
- `DBName` - Database name

### Storage Stack Outputs
- `DocumentsBucketName` - Documents bucket name
- `DocumentsBucketArn` - Documents bucket ARN
- `DataLakeBucketName` - Data lake bucket name
- `DataLakeBucketArn` - Data lake bucket ARN
- `SharedModelsBucketName` - Shared models bucket name
- `SharedModelsBucketArn` - Shared models bucket ARN

### Compute Stack Outputs
- `ECRBackendRepositoryUri` - Backend ECR repository URI
- `ECRFrontendRepositoryUri` - Frontend ECR repository URI
- `ECSClusterName` - ECS cluster name
- `ALBDnsName` - ALB DNS name
- `ALBArn` - ALB ARN
- `BackendServiceName` - Backend service name
- `FrontendServiceName` - Frontend service name

### Async Stack Outputs
- `ProcessingQueueUrl` - Processing queue URL
- `ProcessingQueueArn` - Processing queue ARN
- `NotificationQueueUrl` - Notification queue URL
- `NotificationQueueArn` - Notification queue ARN
- `DataIngestionQueueUrl` - Data ingestion queue URL
- `DataIngestionQueueArn` - Data ingestion queue ARN
- `LambdaExecutionRoleArn` - Lambda execution role ARN

### Monitoring Stack Outputs
- `SNSTopicArn` - SNS topic ARN for alerts
- `DashboardUrl` - CloudWatch dashboard URL

## Notes on Placeholder Implementation

⚠️ **Important:** These CloudFormation templates are currently placeholders. The `Resources` sections contain TODO comments indicating what needs to be implemented. The templates have:

- ✅ Complete parameter definitions
- ✅ Complete output definitions
- ✅ Proper structure and formatting
- ⚠️ Placeholder resources (commented TODOs)

Before deploying, you must:
1. Implement the actual CloudFormation resources based on the TODO comments
2. Update the deployment scripts to use actual AWS CLI commands
3. Test deployments in a development environment first

## Troubleshooting

### Stack deployment fails
- Check AWS credentials are configured correctly
- Verify parameter values are valid
- Check CloudFormation console for detailed error messages
- Ensure dependent stacks are deployed first

### Cannot connect to RDS
- Verify security groups allow connections from ECS security group
- Check that RDS is in private subnets
- Verify database password is set correctly

### ALB not accessible
- Check that ALB is in public subnets
- Verify security groups allow HTTP/HTTPS traffic
- Ensure ACM certificate is in the same region as ALB

## Security Considerations

- Never commit sensitive values (passwords, API keys) to parameter files
- Use AWS Secrets Manager for sensitive parameters in production
- Enable Multi-AZ for production databases
- Use 3 NAT gateways for production (high availability)
- Enable deletion protection for production stacks
- Regularly review and update security group rules

## Cost Optimization

- Development environment uses single NAT gateway (saves ~$32/month per additional NAT)
- Use appropriate instance sizes for each environment
- Enable S3 lifecycle policies to archive old data to Glacier
- Use Fargate Spot for non-critical workloads (future enhancement)

## Support

For issues or questions, please refer to the main project documentation.
