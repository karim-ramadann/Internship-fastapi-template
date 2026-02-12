# Database Module

Thin wrapper around [`terraform-aws-modules/rds/aws`](https://registry.terraform.io/modules/terraform-aws-modules/rds/aws/latest) for PostgreSQL on RDS.

## What it does

- Creates an RDS PostgreSQL instance with environment-aware defaults (encryption, backups, deletion protection)
- Creates a DB subnet group from private subnets
- Generates a random master password and stores credentials in Secrets Manager
- Enables Performance Insights and Enhanced Monitoring in production
- Configures auto-scaling storage up to 2x the allocated amount
- Exports CloudWatch logs for PostgreSQL and upgrade events

## Usage

```hcl
module "database" {
  source = "./modules/database"

  context = local.context

  private_subnet_ids    = module.networking.private_subnet_ids
  rds_security_group_id = module.security.rds_security_group_id
  rds_instance_class    = "db.t3.micro"
  rds_allocated_storage = 20
  db_name               = "app"
  db_username           = "postgres"
}
```

## Inputs

See [variables.tf](./variables.tf) for the full list.

## Outputs

See [outputs.tf](./outputs.tf) for the full list.

## Upstream Module

- [terraform-aws-modules/rds/aws](https://registry.terraform.io/modules/terraform-aws-modules/rds/aws/latest)
