terraform {
  backend "s3" {
    bucket = "digico-fullstack-tfstate-bucket"
    region = "us-east-1"
    # key is passed via -backend-config per environment
    # Example: -backend-config=environments/staging/backend.hcl
  }
}
