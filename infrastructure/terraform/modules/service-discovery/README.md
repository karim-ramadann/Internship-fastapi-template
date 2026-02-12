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
