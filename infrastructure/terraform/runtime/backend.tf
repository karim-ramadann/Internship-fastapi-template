terraform {
  backend "s3" {
    # Backend configuration is loaded from environment-specific files
    # See: runtime/environments/{env}/backend.hcl
    # 
    # Each environment can use different S3 buckets/regions if needed:
    #   - runtime/environments/dev/backend.hcl
    #   - runtime/environments/staging/backend.hcl
    #   - runtime/environments/production/backend.hcl
    #
    # Example: make init-dev loads environments/dev/backend.hcl
  }
}
