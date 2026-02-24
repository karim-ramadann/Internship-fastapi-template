# ============================================================================
# DATA SOURCES - AWS Account, Region, Availability Zones
# ============================================================================

# Current AWS account and caller identity
data "aws_caller_identity" "current" {}

# Validation check for account ID
# This is separate from the data source to allow using local values
resource "null_resource" "account_validation" {
  lifecycle {
    precondition {
      condition = (
        lookup(local.account_ids, var.environment, null) == null ||
        data.aws_caller_identity.current.account_id == lookup(local.account_ids, var.environment, null)
      )
      error_message = <<-EOT
        ❌ DEPLOYMENT BLOCKED: AWS Account Mismatch!
        
        Environment:       ${var.environment}
        Current Account:   ${data.aws_caller_identity.current.account_id}
        Expected Account:  ${lookup(local.account_ids, var.environment, "not configured")}
        
        You are attempting to deploy the '${var.environment}' environment to the wrong AWS account.
        Please check your AWS credentials and ensure you're authenticated to the correct account.
        
        Account IDs are defined in locals.tf
      EOT
    }
  }
}

# Available availability zones in the region
data "aws_availability_zones" "available" {
  state = "available"
}
