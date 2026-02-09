# Automated ACM Certificate & Route53 DNS Management

## Overview

The infrastructure now includes **fully automated** ACM certificate management and Route53 DNS configuration. No manual certificate requests or DNS configuration required!

## What's Automated

### ✅ ACM Certificate Management
- Automatically requests wildcard certificate (`*.yourdomain.com`)
- Creates DNS validation records in Route53
- Waits for certificate validation to complete (5-15 minutes)
- Provides validated certificate ARN to ALB

### ✅ Route53 DNS Records
- Creates hosted zone (optional) or uses existing
- Automatically creates A records for:
  - `api.{domain}` → ALB
  - `dashboard.{domain}` → ALB
  - `adminer.{domain}` → ALB
- Uses Route53 Alias records (no propagation delay, better performance)

## New Modules

### 1. `modules/route53/`

**Purpose**: Manages Route53 hosted zone and DNS records

**Resources**:
- `aws_route53_zone` (optional) - Creates hosted zone
- `aws_route53_record` (3) - A records for api, dashboard, adminer

**Variables**:
- `domain` - Domain name
- `create_hosted_zone` - Whether to create or use existing zone
- `alb_dns_name` - ALB DNS for alias records
- `alb_zone_id` - ALB zone for alias records

**Outputs**:
- `zone_id` - Hosted zone ID
- `zone_name_servers` - Name servers (if created)
- `backend_fqdn`, `frontend_fqdn`, `adminer_fqdn` - FQDNs

### 2. `modules/acm/`

**Purpose**: Manages ACM certificates with automatic DNS validation

**Resources**:
- `aws_acm_certificate` - Wildcard certificate request
- `aws_route53_record` (multiple) - DNS validation records
- `aws_acm_certificate_validation` - Waits for validation

**Variables**:
- `domain` - Domain name
- `route53_zone_id` - Zone for validation records

**Outputs**:
- `certificate_arn` - Validated certificate ARN
- `certificate_status` - Certificate status

## Configuration Changes

### Removed Variables
- ❌ `certificate_arn` (was required in terraform.tfvars)

### New Variables
- ✅ `create_hosted_zone` (default: false)

### Updated terraform.tfvars

**Before**:
```hcl
domain          = "staging.example.com"
certificate_arn = "arn:aws:acm:us-east-1:123456789012:certificate/XXXXX"
```

**After**:
```hcl
domain             = "staging.example.com"
create_hosted_zone = false  # Set to true if you need a new zone
```

## Deployment Flow

### Terraform Module Order

1. **Route53 Module** - Creates/references hosted zone
2. **ACM Module** - Requests certificate, creates validation records
3. **Load Balancer Module** - Uses validated certificate
4. **Route53 DNS Records** - Points domains to ALB

This order ensures:
- Zone exists before certificate validation
- Certificate is validated before ALB creation
- DNS records created after ALB is available

### Timing

```
terraform apply execution:
├── Route53 zone creation (if needed): ~30s
├── ACM certificate request: ~5s
├── DNS validation records: ~30s
├── Certificate validation wait: 5-15 minutes ⏰
├── Infrastructure creation: 10-15 minutes
└── DNS records creation: ~30s

Total: 15-30 minutes (first run)
```

## Usage Scenarios

### Scenario 1: New Project, New Domain
```hcl
# terraform.tfvars
domain             = "newproject.com"
create_hosted_zone = true
```

**Steps**:
1. `terraform apply` (creates everything)
2. Get name servers: `terraform output route53_name_servers`
3. Update domain registrar with name servers
4. Wait 24-48 hours for propagation
5. Done!

### Scenario 2: Existing Route53 Zone
```hcl
# terraform.tfvars
domain             = "existing.com"
create_hosted_zone = false
```

**Steps**:
1. Ensure hosted zone exists in Route53
2. `terraform apply` (uses existing zone)
3. Done! Certificate and DNS configured automatically

### Scenario 3: Subdomain Deployment
```hcl
# terraform.tfvars
domain             = "staging.existing.com"
create_hosted_zone = true  # Creates zone for subdomain
```

**Steps**:
1. `terraform apply` (creates subdomain zone)
2. Get name servers: `terraform output route53_name_servers`
3. Create NS record in parent zone pointing to these name servers
4. Done!

## Benefits

### Before (Manual)
- ⏰ Request certificate in ACM console
- ⏰ Copy validation CNAME records
- ⏰ Add validation records to Route53
- ⏰ Wait for validation
- ⏰ Copy certificate ARN to terraform.tfvars
- ⏰ Create DNS records for api/dashboard/adminer
- ❌ Manual steps prone to errors
- ❌ Certificate ARN must be managed per environment

### After (Automated)
- ✅ Set `domain` in terraform.tfvars
- ✅ Run `terraform apply`
- ✅ Everything happens automatically
- ✅ Certificate ARN managed by Terraform
- ✅ DNS records created automatically
- ✅ Zero manual steps
- ✅ Reproducible across environments

## Certificate Validation Process

Terraform uses **DNS validation** (recommended by AWS):

1. **Request Certificate**: Terraform requests wildcard cert
2. **Create Validation Records**: Terraform creates CNAME records
3. **Wait for Validation**: Terraform polls ACM until validated
4. **Provide to ALB**: Certificate ARN passed to load balancer

All automatic, no manual intervention needed!

## Security Notes

- ✅ Wildcard certificate (`*.domain.com`) covers all subdomains
- ✅ Certificate auto-renewal handled by AWS
- ✅ Private key never exposed (managed by AWS)
- ✅ DNS validation more secure than email validation
- ✅ Certificate ARN in Terraform state (encrypted S3 backend)

## Troubleshooting

### Certificate Validation Timeout

**Issue**: Certificate stuck in "Pending Validation"

**Solution**:
1. Check if Route53 zone is accessible
2. Verify domain ownership
3. Check DNS propagation: `dig _acme-challenge.yourdomain.com`
4. Increase timeout in `modules/acm/main.tf` if needed

### Name Server Not Updated

**Issue**: DNS not resolving after terraform apply

**Solution**:
1. Get name servers: `terraform output route53_name_servers`
2. Check domain registrar NS records
3. Wait for propagation (can take 24-48 hours)
4. Test: `dig NS yourdomain.com`

### Zone Already Exists

**Issue**: Error "Hosted zone already exists"

**Solution**:
1. Set `create_hosted_zone = false` in terraform.tfvars
2. Terraform will use existing zone

## Outputs

After `terraform apply`, useful outputs:

```bash
# Certificate ARN
terraform output certificate_arn

# Name servers (if created zone)
terraform output route53_name_servers

# Application URLs
terraform output application_urls

# Zone ID
terraform output route53_zone_id
```

## Migration from Manual Setup

If you previously created certificates manually:

1. **Option A: Import Existing Certificate** (not recommended)
   - Complex, manual ARN management
   
2. **Option B: Let Terraform Create New Certificate** (recommended)
   - Set `create_hosted_zone = false` (use existing zone)
   - Run `terraform apply`
   - New certificate created automatically
   - Old certificate can be deleted manually

## Cost Impact

### Route53
- **Hosted Zone**: $0.50/month per zone
- **DNS Queries**: $0.40 per million queries (first million free)
- **Alias Queries**: Free

### ACM
- **Certificate**: Free (AWS-managed)
- **Renewal**: Free (automatic)

**Total Additional Cost**: ~$0.50-1.00/month

## Comparison: Manual vs Automated

| Task | Manual | Automated |
|------|--------|-----------|
| Request certificate | AWS Console | Terraform |
| DNS validation | Copy/paste CNAMEs | Automatic |
| Wait for validation | Manual check | Terraform waits |
| Update terraform.tfvars | Copy ARN | Not needed |
| Create DNS records | Route53 console | Terraform |
| Update records on ALB change | Manual | Automatic |
| Per-environment setup | Repeat all steps | Same code |
| **Total Time** | 30-45 mins | 0 mins (automated) |
| **Error Prone** | Yes | No |
| **Reproducible** | No | Yes |

## Best Practices

1. **Use existing hosted zones** when possible (`create_hosted_zone = false`)
2. **Separate zones per environment** (staging.example.com, production.example.com)
3. **Document name servers** if creating new zones
4. **Monitor certificate expiry** (though AWS auto-renews)
5. **Test in staging first** before applying to production

## Summary

The infrastructure is now **100% code-managed** for DNS and certificates:

✅ No manual certificate requests
✅ No manual DNS configuration
✅ No certificate ARN management
✅ Fully automated validation
✅ Reproducible across environments
✅ Production-ready security

**One command deploys everything**: `terraform apply` 🚀
