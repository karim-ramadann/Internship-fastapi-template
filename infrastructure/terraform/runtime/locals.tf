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

  # Use first 2 availability zones
  availability_zones = slice(data.aws_availability_zones.available.names, 0, 2)

  # Subnet CIDR blocks
  public_subnet_cidrs   = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnet_cidrs  = ["10.0.10.0/24", "10.0.11.0/24"]
  database_subnet_cidrs = ["10.0.20.0/24", "10.0.21.0/24"]

  # Log retention based on environment
  log_retention_days = var.environment == "production" ? 30 : 7

  # Enable alarms for production
  enable_alarms = var.environment == "production"
}
