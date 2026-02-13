<!-- BEGIN_TF_DOCS -->


## Usage

```hcl
module "example" {
  source = "../modules/this-module"
  
  context = {
    project     = "my-project"
    environment = "dev"
    region      = "us-east-1"
    common_tags = {
      Environment = "dev"
      ManagedBy   = "terraform"
    }
  }
  
  # Add required variables here
}
```

## Requirements

No requirements.

## Providers

No providers.

## Modules

No modules.

## Resources

No resources.

## Inputs

No inputs.

## Outputs

No outputs.
<!-- END_TF_DOCS -->