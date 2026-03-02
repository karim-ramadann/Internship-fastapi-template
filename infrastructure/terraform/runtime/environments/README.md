# Environment Configurations

This directory contains environment-specific Terraform variable files.

## Structure

```
environments/
├── dev/
│   ├── terraform.tfvars          # Development environment variables
│   └── backend.hcl               # Development S3 backend configuration
├── staging/
│   ├── terraform.tfvars          # Staging environment variables
│   └── backend.hcl               # Staging S3 backend configuration
└── production/
    ├── terraform.tfvars          # Production environment variables
    └── backend.hcl               # Production S3 backend configuration
```

## Usage

Each environment has its own `terraform.tfvars` file that defines environment-specific values such as:
- Instance sizes
- Scaling parameters
- Network configuration
- Application settings

### Deploying to an Environment

From the terraform root directory:

```bash
# Development
make init-dev
make plan-dev
make apply-dev

# Staging
make init-staging
make plan-staging
make apply-staging

# Production
make init-production
make plan-production
make apply-production
```

Or manually from the runtime directory:

```bash
# Development
terraform init -backend-config=environments/dev/backend.hcl
terraform plan -var-file=environments/dev/terraform.tfvars
terraform apply -var-file=environments/dev/terraform.tfvars

# Staging
terraform init -backend-config=environments/staging/backend.hcl
terraform plan -var-file=environments/staging/terraform.tfvars
terraform apply -var-file=environments/staging/terraform.tfvars

# Production
terraform init -backend-config=environments/production/backend.hcl
terraform plan -var-file=environments/production/terraform.tfvars
terraform apply -var-file=environments/production/terraform.tfvars
```

## Required Secrets

The following secrets must be set via environment variables before running Terraform:

```bash
export TF_VAR_secret_key="your-secret-key"
export TF_VAR_first_superuser_password="admin-password"
export TF_VAR_smtp_password="smtp-password"  # Optional if not using email
```

You can also create a `.envrc` file (see `.envrc.example` in the terraform root) and use [direnv](https://direnv.net/) to automatically load these variables.

## Variable Precedence

Terraform loads variables in the following order (later sources override earlier ones):

1. Environment variables (`TF_VAR_name`)
2. `terraform.tfvars` file (from environments/ directory)
3. `*.auto.tfvars` files (alphabetically)
4. `-var` and `-var-file` command-line flags (in order specified)

## AWS Account ID Management

Each environment should deploy to a specific AWS account. To prevent accidental deployments to the wrong account, all account IDs are centrally managed in `../locals.tf` and automatically validated based on the environment variable.

### Setting Up Account Validation

1. **Get your AWS account IDs:**
   ```bash
   aws sts get-caller-identity --query Account --output text
   ```

2. **Update the account_ids map in `locals.tf`:**
   ```hcl
   # In terraform/runtime/locals.tf
   locals {
     account_ids = {
       dev        = "123456789012"  # Your dev account ID
       staging    = "234567890123"  # Your staging account ID
       production = "345678901234"  # Your production account ID
     }
   }
   ```

3. **Terraform will automatically validate** that you're deploying to the correct account based on the `environment` variable.
   - If the current AWS account doesn't match the expected account for that environment, deployment will be blocked
   - Set to `null` to disable validation for a specific environment

### How It Works

- Account IDs are defined once in `locals.tf` in a map indexed by environment name
- Terraform automatically looks up the expected account ID using `var.environment`
- A precondition check validates the current account matches the expected account
- Clear error messages show any mismatch before resources are created

### Pre-Deployment Validation Script

For an extra safety check before running Terraform commands, use the validation script:

```bash
# From the runtime directory
./scripts/validate-account.sh dev
./scripts/validate-account.sh production
```

This script checks your current AWS credentials against the expected account ID and provides clear error messages if there's a mismatch.

### Account ID References in Code

The current AWS account ID is available throughout your Terraform configuration:

- **Via data source**: `data.aws_caller_identity.current.account_id`
- **Via local**: `local.account_id` (recommended for cleaner code)
- **Expected account**: `local.expected_account_id` (the account ID for current environment)

Example usage in IAM policies:
```hcl
resource "aws_s3_bucket_policy" "example" {
  statement {
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${local.account_id}:root"]
    }
  }
}
```

### Benefits of This Approach

- **Centralized Management**: All account IDs in one place (`locals.tf`)
- **Automatic Validation**: No need to set account IDs in each environment's tfvars
- **Environment-Aware**: Uses the `environment` variable to determine the expected account
- **Easy Maintenance**: Add new environments by just updating the map in locals.tf

## Security Best Practices

1. **Never commit secrets** to the tfvars files
2. **Set account IDs** in each environment's tfvars to prevent wrong-account deployments
3. Use **environment variables** for sensitive data (`TF_VAR_*`)
4. Store production secrets in a **secrets manager** (AWS Secrets Manager, HashiCorp Vault, etc.)
5. Use **`.envrc`** with direnv for local development
6. In CI/CD, use the platform's **secrets management** (GitHub Secrets, GitLab CI/CD Variables, etc.)
7. **Validate AWS account** before deployments using the provided script or Terraform's built-in validation

## Environment Differences

### Development
- Optimized for cost (smaller instances, single NAT Gateway)
- Auto-scaling disabled
- Single-AZ RDS
- Minimal backup retention

### Staging
- Production-like configuration for testing
- Moderate instance sizes
- Optional Multi-AZ
- Auto-scaling enabled with conservative limits

### Production
- High availability (Multi-AZ, NAT per AZ)
- Larger instance sizes
- Aggressive auto-scaling
- Extended backup retention
- Deletion protection enabled

## Adding a New Environment

To add a new environment (e.g., `qa`):

1. Create the directory and tfvars file:
   ```bash
   mkdir -p environments/qa
   cp environments/staging/terraform.tfvars environments/qa/terraform.tfvars
   ```

2. Update the values in `environments/qa/terraform.tfvars`

3. Create a backend configuration file:
   ```bash
   cat > environments/qa/backend.hcl <<EOF
   bucket = "digico-fullstack-tfstate-bucket-development"
   key    = "runtime/environments/qa/terraform.tfstate"
   region = "eu-west-1"
   EOF
   ```

4. Add Make targets to the main Makefile:
   ```makefile
   init-qa:
       cd runtime && terraform init -backend-config=environments/qa/backend.hcl

   plan-qa:
       cd runtime && terraform plan -var-file=environments/qa/terraform.tfvars

   apply-qa:
       cd runtime && terraform apply -var-file=environments/qa/terraform.tfvars
   ```

5. Deploy:
   ```bash
   make init-qa
   make apply-qa
   ```

## Backend Configuration

Each environment has a `backend.hcl` file that specifies:
- **bucket**: S3 bucket name for storing Terraform state
- **key**: Unique path within the bucket for this environment's state
- **region**: AWS region where the S3 bucket resides

**Example (`environments/dev/backend.hcl`):**
```hcl
bucket = "digico-fullstack-tfstate-bucket-development"
key    = "runtime/environments/dev/terraform.tfstate"
region = "eu-west-1"
```

### Using Different Buckets Per Environment

You can configure each environment to use a different S3 bucket:

```hcl
# Development - shared bucket
bucket = "digico-fullstack-tfstate-bucket-development"

# Staging - shared bucket
bucket = "digico-fullstack-tfstate-bucket-development"

# Production - dedicated bucket
bucket = "digico-fullstack-tfstate-bucket-production"
```
