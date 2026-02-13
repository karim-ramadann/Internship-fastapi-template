# ============================================================================
# DATA SOURCES - AWS Account, Region, Availability Zones
# ============================================================================

# Current AWS account and caller identity
data "aws_caller_identity" "current" {}

# Current AWS region
data "aws_region" "current" {}

# Available availability zones in the region
data "aws_availability_zones" "available" {
  state = "available"
}
