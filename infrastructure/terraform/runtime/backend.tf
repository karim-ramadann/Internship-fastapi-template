terraform {
  backend "s3" {
    bucket       = "digico-fullstack-tfstate-bucket-development"
    region       = "eu-west-1"
    use_lockfile = true
    # key is passed via -backend-config per environment
    # Example: -backend-config=environments/dev/backend.hcl
  }
}
