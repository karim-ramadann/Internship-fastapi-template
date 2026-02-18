# Staging Deployment Guide (ECS + Terraform)

## Prerequisites

- AWS CLI configured with credentials for account `782017371239`
- Terraform >= 1.11.0
- Docker installed
- Domain: `testing.digico.solutions`

---

## 1. Delete Old Secrets (if scheduled for deletion)

If you previously destroyed the infrastructure, Secrets Manager secrets may still be scheduled for deletion (7-day recovery window for non-production). Terraform will fail to create them again until they're fully deleted or restored.

```bash
# Check if secrets are pending deletion
aws secretsmanager describe-secret \
  --secret-id "staging/fastapi/app/secrets" \
  --region eu-west-1 2>/dev/null | grep -i "DeletedDate"

aws secretsmanager describe-secret \
  --secret-id "staging/fastapi/database/credentials" \
  --region eu-west-1 2>/dev/null | grep -i "DeletedDate"

# Force delete any secrets stuck in scheduled deletion
aws secretsmanager delete-secret \
  --secret-id "staging/fastapi/app/secrets" \
  --force-delete-without-recovery \
  --region eu-west-1 2>/dev/null

aws secretsmanager delete-secret \
  --secret-id "staging/fastapi/database/credentials" \
  --force-delete-without-recovery \
  --region eu-west-1 2>/dev/null
```

If the secrets don't exist yet, these commands will simply error with "not found" — that's fine.

---

## 2. Initialize Terraform

```bash
cd infrastructure/terraform
make init-staging
```

Or manually:

```bash
cd infrastructure/terraform/runtime
terraform init -backend-config=environments/staging/backend.hcl
```

---

## 3. Plan & Apply Infrastructure

```bash
make plan-staging
make apply-staging
```

> **Note**: The first apply will create the ACM certificate but it will remain in `PENDING_VALIDATION` status until you manually verify it in Route53 (step 4). The ALB listener requires a valid cert, so the apply may hang or fail at the ALB step until the cert is validated.

---

## 4. Verify ACM Certificate in Route53

Since the hosted zone is in an external account, DNS validation records must be created manually.

After `terraform apply`, get the validation records:

```bash
cd infrastructure/terraform/runtime
terraform output acm_validation_records
```

This will output something like:

```
{
  "testing.digico.solutions" = {
    name  = "_abc123.testing.digico.solutions."
    type  = "CNAME"
    value = "_xyz789.acm-validations.aws."
  }
  "*.testing.digico.solutions" = {
    name  = "_abc123.testing.digico.solutions."
    type  = "CNAME"
    value = "_xyz789.acm-validations.aws."
  }
}
```

Go to the **Route53 hosted zone** for `digico.solutions` (in the account that manages DNS) and create the CNAME record(s) shown above.

Wait for the certificate status to change to `ISSUED` (usually 5-15 minutes):

```bash
aws acm describe-certificate \
  --certificate-arn $(terraform output -raw acm_certificate_arn) \
  --region eu-west-1 \
  --query 'Certificate.Status'
```

Once validated, re-run `terraform apply` if the first one failed at the ALB:

```bash
make apply-staging
```

---

## 5. Create Route53 A Record for ALB

In the hosted zone account, create an A record (Alias) pointing to the ALB:

```bash
# Get the ALB DNS name
cd infrastructure/terraform/runtime
terraform output alb_dns_name
```

In Route53, create:

| Type | Name | Value |
|------|------|-------|
| A (Alias) | `testing.digico.solutions` | ALB DNS name (select the ALB from the alias target dropdown) |

---

## 6. Build and Push Docker Image to ECR

```bash
# Get ECR URL and region
cd infrastructure/terraform/runtime
ECR_URL=$(terraform output -raw ecr_repository_url)
AWS_REGION=$(terraform output -raw aws_region)

# Login to ECR
aws ecr get-login-password --region $AWS_REGION | \
  docker login --username AWS --password-stdin $ECR_URL

# Build the backend image for amd64 (ECS Fargate requires linux/amd64)
# This is important when building on Apple Silicon (M1/M2/M3) Macs
cd ../../..
docker build --platform linux/amd64 -t fastapi-backend:staging-latest -f backend/Dockerfile .

# Tag and push
docker tag fastapi-backend:staging-latest $ECR_URL:staging-latest
docker push $ECR_URL:staging-latest
```

---

## 7. Run Database Migrations (Standalone ECS Task)

After the first deploy (or when there are new migrations), run the prestart script as a one-off ECS task. This runs `alembic upgrade head` and creates initial data.

```bash
cd infrastructure/terraform/runtime

# Get the values needed for the task
TASK_DEF=$(terraform output -raw ecs_task_definition_arn)
CLUSTER=$(terraform output -raw ecs_cluster_name)

# Get subnets and security group from the service config
SUBNETS=$(aws ecs describe-services \
  --cluster $CLUSTER \
  --services $(terraform output -raw ecs_service_name) \
  --region eu-west-1 \
  --query 'services[0].networkConfiguration.awsvpcConfiguration.subnets' \
  --output text | tr '\t' ',')

SG=$(aws ecs describe-services \
  --cluster $CLUSTER \
  --services $(terraform output -raw ecs_service_name) \
  --region eu-west-1 \
  --query 'services[0].networkConfiguration.awsvpcConfiguration.securityGroups[0]' \
  --output text)

# Run the migration task
TASK_ARN=$(aws ecs run-task \
  --cluster $CLUSTER \
  --task-definition $TASK_DEF \
  --launch-type FARGATE \
  --network-configuration "awsvpcConfiguration={subnets=[$SUBNETS],securityGroups=[$SG],assignPublicIp=DISABLED}" \
  --overrides '{"containerOverrides":[{"name":"backend","command":["bash","scripts/prestart.sh"]}]}' \
  --region eu-west-1 \
  --query 'tasks[0].taskArn' \
  --output text)

echo "Migration task started: $TASK_ARN"

# Wait for it to complete
aws ecs wait tasks-stopped --cluster $CLUSTER --tasks $TASK_ARN --region eu-west-1

# Verify exit code (should be 0)
aws ecs describe-tasks \
  --cluster $CLUSTER \
  --tasks $TASK_ARN \
  --region eu-west-1 \
  --query 'tasks[0].containers[0].exitCode'
```

Check the logs to confirm migrations ran:

```bash
aws logs tail /ecs/staging/fastapi/backend --since 10m --region eu-west-1 | grep -i "alembic\|migration\|initial data"
```

---

## 8. Force ECS Deployment

After pushing the image, force ECS to pick up the new image:

```bash
cd infrastructure/terraform/runtime
CLUSTER=$(terraform output -raw ecs_cluster_name)
SERVICE=$(terraform output -raw ecs_service_name)

aws ecs update-service \
  --cluster $CLUSTER \
  --service $SERVICE \
  --force-new-deployment \
  --region eu-west-1
```

---

## 9. Verify Deployment

```bash
# Check ECS service status
aws ecs describe-services \
  --cluster $CLUSTER \
  --services $SERVICE \
  --region eu-west-1 \
  --query 'services[0].{status:status,running:runningCount,desired:desiredCount,deployments:deployments[*].rolloutState}'

# Tail logs
aws logs tail /ecs/staging/fastapi/backend --follow --region eu-west-1

# Test the API
curl https://testing.digico.solutions/api/v1/utils/health-check/
```

---

## Troubleshooting

**Secrets Manager "already scheduled for deletion"**: Run the force-delete commands from step 1.

**ACM cert stuck in PENDING_VALIDATION**: Double-check the CNAME records in Route53 match exactly what `terraform output acm_validation_records` shows.

**ECS tasks failing to start**: Check CloudWatch logs and verify the image exists in ECR:
```bash
aws ecr describe-images --repository-name $(terraform output -raw ecr_repository_url | sed 's|.*/||') --region eu-west-1
```

**ALB health checks failing**: Ensure the backend container is listening on port 8000 and the health check path `/api/v1/utils/health-check/` returns 200.
