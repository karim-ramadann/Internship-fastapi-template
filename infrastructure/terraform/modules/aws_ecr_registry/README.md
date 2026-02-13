<!-- BEGIN_TF_DOCS -->
# ECR Registry Configuration Module

Thin wrapper around [terraform-aws-modules/ecr/aws](https://registry.terraform.io/modules/terraform-aws-modules/ecr/aws/latest).

This module manages AWS ECR registry-level settings (not individual repositories):
- Registry scanning configuration (ENHANCED or BASIC)
- Cross-region and cross-account replication rules
- Registry policy for permissions
- Pull-through cache rules for upstream registries (Docker Hub, ECR Public, etc.)

Note: ECR Registry is a regional resource with one registry per AWS account per region.

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

| Name | Source | Version |
|------|--------|---------|
| <a name="module_ecr"></a> [ecr](#module\_ecr) | terraform-aws-modules/ecr/aws | ~> 2.3 |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_context"></a> [context](#input\_context) | Context object containing project, environment, region, and common tags | <pre>object({<br/>    project     = string<br/>    environment = string<br/>    region      = string<br/>    common_tags = map(string)<br/>  })</pre> | n/a | yes |
| <a name="input_create_registry_policy"></a> [create\_registry\_policy](#input\_create\_registry\_policy) | Determines whether a registry policy will be created | `bool` | `false` | no |
| <a name="input_create_registry_replication_configuration"></a> [create\_registry\_replication\_configuration](#input\_create\_registry\_replication\_configuration) | Determines whether a registry replication configuration will be created | `bool` | `false` | no |
| <a name="input_manage_registry_scanning_configuration"></a> [manage\_registry\_scanning\_configuration](#input\_manage\_registry\_scanning\_configuration) | Determines whether the registry scanning configuration will be managed | `bool` | `false` | no |
| <a name="input_pull_through_cache_rules"></a> [pull\_through\_cache\_rules](#input\_pull\_through\_cache\_rules) | Map of pull through cache rules to create | <pre>map(object({<br/>    ecr_repository_prefix      = string<br/>    upstream_registry_url      = string<br/>    credential_arn             = optional(string)<br/>    custom_role_arn            = optional(string)<br/>    upstream_repository_prefix = optional(string)<br/>    region                     = optional(string)<br/>  }))</pre> | `{}` | no |
| <a name="input_registry_policy"></a> [registry\_policy](#input\_registry\_policy) | The policy document for the registry (JSON formatted string) | `string` | `null` | no |
| <a name="input_registry_replication_rules"></a> [registry\_replication\_rules](#input\_registry\_replication\_rules) | The replication rules for a replication configuration. A maximum of 10 are allowed | <pre>list(object({<br/>    destinations = list(object({<br/>      region      = string<br/>      registry_id = string<br/>    }))<br/>    repository_filters = optional(list(object({<br/>      filter      = string<br/>      filter_type = string<br/>    })))<br/>  }))</pre> | `null` | no |
| <a name="input_registry_scan_rules"></a> [registry\_scan\_rules](#input\_registry\_scan\_rules) | One or multiple blocks specifying scanning rules to determine which repository filters are used and at what frequency scanning will occur | <pre>list(object({<br/>    scan_frequency = string<br/>    filter = list(object({<br/>      filter      = string<br/>      filter_type = optional(string)<br/>    }))<br/>  }))</pre> | `null` | no |
| <a name="input_registry_scan_type"></a> [registry\_scan\_type](#input\_registry\_scan\_type) | The scanning type to set for the registry. Can be either ENHANCED or BASIC | `string` | `"ENHANCED"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_pull_through_cache_rules"></a> [pull\_through\_cache\_rules](#output\_pull\_through\_cache\_rules) | Map of pull through cache rules configured |
| <a name="output_registry_id"></a> [registry\_id](#output\_registry\_id) | The registry ID where the registry configuration is applied |
| <a name="output_registry_policy_text"></a> [registry\_policy\_text](#output\_registry\_policy\_text) | The registry policy text |
| <a name="output_registry_replication_configuration_id"></a> [registry\_replication\_configuration\_id](#output\_registry\_replication\_configuration\_id) | The ID of the registry replication configuration |
| <a name="output_registry_scanning_configuration_id"></a> [registry\_scanning\_configuration\_id](#output\_registry\_scanning\_configuration\_id) | The ID of the registry scanning configuration |
<!-- END_TF_DOCS -->