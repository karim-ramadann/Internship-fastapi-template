# Route53 Module

DNS management for the application with ALB alias records.

## What it does

- Creates or references an existing Route53 hosted zone
- Creates ALB alias A-records for backend (`api.`), frontend (`dashboard.`), and adminer (`adminer.`)
- Outputs FQDNs and zone name servers for domain registrar configuration

## Usage

```hcl
module "route53" {
  source = "./modules/route53"

  context = local.context

  domain             = "example.com"
  create_hosted_zone = true
  alb_dns_name       = module.load_balancer.alb_dns_name
  alb_zone_id        = module.load_balancer.alb_zone_id
}
```

## Inputs

See [variables.tf](./variables.tf) for the full list.

## Outputs

See [outputs.tf](./outputs.tf) for the full list.
