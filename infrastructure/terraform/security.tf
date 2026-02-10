# ============================================================================
# SECURITY - Security Groups, IAM Roles, Policies
# ============================================================================

# Security Module (wrapper for security groups and IAM roles)
module "security" {
  source = "./modules/security"

  context = local.context
  vpc_id  = module.networking.vpc_id
}
