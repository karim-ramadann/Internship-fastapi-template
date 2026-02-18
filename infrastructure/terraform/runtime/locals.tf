locals {
  # AWS Account IDs per Environment
  # TODO: Update these with your actual AWS account IDs (12-digit numbers)
  # Set to null to disable validation for a specific environment
  account_ids = {
    dev        = "782017371239" # Development account
    staging    = "782017371239" # Staging account
    production = "782017371239" # Production account
  }

  # Current AWS account information
  account_id = data.aws_caller_identity.current.account_id

  # Context object passed to all modules
  context = {
    project     = var.project
    environment = var.environment
    region      = var.aws_region
    account_id  = local.account_id
    common_tags = merge(
      var.common_tags,
      {
        Environment = var.environment
        Project     = var.project
        ManagedBy   = "terraform"
      }
    )
  }

  # Use first 2 availability zones
  availability_zones = slice(data.aws_availability_zones.available.names, 0, 2)


}
