locals {
  # Context object passed to all modules
  context = {
    project     = var.project
    environment = var.environment
    region      = var.aws_region
    common_tags = merge(
      var.common_tags,
      {
        Environment = var.environment
        Project     = var.project
        ManagedBy   = "terraform"
      }
    )
  }

  # Naming convention
  name_prefix = "${var.project}-${var.environment}"

  # Log retention based on environment
  log_retention_days = var.environment == "production" ? 30 : 7

  # Enable alarms for production
  enable_alarms = var.environment == "production"
}
