# Service Discovery Module

AWS Cloud Map private DNS namespace and service registrations.

## What it does

- Creates a private DNS namespace (`{project}-{environment}.local`) in Cloud Map
- Registers `backend` and `frontend` services with A-record DNS and multivalue routing
- Custom health check with failure threshold of 1
- Used by ECS services for internal service-to-service communication

## Usage

```hcl
module "service_discovery" {
  source = "./modules/service-discovery"

  context = local.context
  vpc_id  = module.networking.vpc_id
}
```

## Inputs

See [variables.tf](./variables.tf) for the full list.

## Outputs

See [outputs.tf](./outputs.tf) for the full list.

<!-- BEGIN_TF_DOCS -->
# Service Discovery Module

AWS Cloud Map private DNS namespace and service registrations.

## What it does

- Creates a private DNS namespace (`{project}-{environment}.local`) in Cloud Map
- Registers `backend` and `frontend` services with A-record DNS and multivalue routing
- Custom health check with failure threshold of 1
- Used by ECS services for internal service-to-service communication

## Usage

```hcl
module "service_discovery" {
  source = "./modules/service-discovery"

  context = local.context
  vpc_id  = module.networking.vpc_id
}
```

## Inputs

See [variables.tf](./variables.tf) for the full list.

## Outputs

See [outputs.tf](./outputs.tf) for the full list.

## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_service_discovery_private_dns_namespace.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/service_discovery_private_dns_namespace) | resource |
| [aws_service_discovery_service.backend](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/service_discovery_service) | resource |
| [aws_service_discovery_service.frontend](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/service_discovery_service) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_context"></a> [context](#input\_context) | Context object containing project, environment, region, and common tags | <pre>object({<br/>    project     = string<br/>    environment = string<br/>    region      = string<br/>    common_tags = map(string)<br/>  })</pre> | n/a | yes |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | ID of the VPC for the private DNS namespace | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_backend_service_arn"></a> [backend\_service\_arn](#output\_backend\_service\_arn) | ARN of the backend service discovery service |
| <a name="output_backend_service_id"></a> [backend\_service\_id](#output\_backend\_service\_id) | ID of the backend service discovery service |
| <a name="output_frontend_service_arn"></a> [frontend\_service\_arn](#output\_frontend\_service\_arn) | ARN of the frontend service discovery service |
| <a name="output_frontend_service_id"></a> [frontend\_service\_id](#output\_frontend\_service\_id) | ID of the frontend service discovery service |
| <a name="output_namespace_arn"></a> [namespace\_arn](#output\_namespace\_arn) | ARN of the Cloud Map private DNS namespace |
| <a name="output_namespace_id"></a> [namespace\_id](#output\_namespace\_id) | ID of the Cloud Map private DNS namespace |
| <a name="output_namespace_name"></a> [namespace\_name](#output\_namespace\_name) | Name of the Cloud Map private DNS namespace |
<!-- END_TF_DOCS -->