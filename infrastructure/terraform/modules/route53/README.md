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



<!-- BEGIN_TF_DOCS -->
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
| [aws_route53_record.adminer](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record) | resource |
| [aws_route53_record.backend](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record) | resource |
| [aws_route53_record.frontend](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record) | resource |
| [aws_route53_zone.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_zone) | resource |
| [aws_route53_zone.existing](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/route53_zone) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_alb_dns_name"></a> [alb\_dns\_name](#input\_alb\_dns\_name) | DNS name of the Application Load Balancer | `string` | n/a | yes |
| <a name="input_alb_zone_id"></a> [alb\_zone\_id](#input\_alb\_zone\_id) | Zone ID of the Application Load Balancer | `string` | n/a | yes |
| <a name="input_context"></a> [context](#input\_context) | Context object containing project, environment, region, and common tags | <pre>object({<br/>    project     = string<br/>    environment = string<br/>    region      = string<br/>    common_tags = map(string)<br/>  })</pre> | n/a | yes |
| <a name="input_domain"></a> [domain](#input\_domain) | Domain name for the hosted zone | `string` | n/a | yes |
| <a name="input_create_hosted_zone"></a> [create\_hosted\_zone](#input\_create\_hosted\_zone) | Whether to create a new hosted zone or use an existing one | `bool` | `false` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_adminer_fqdn"></a> [adminer\_fqdn](#output\_adminer\_fqdn) | Fully qualified domain name for adminer |
| <a name="output_backend_fqdn"></a> [backend\_fqdn](#output\_backend\_fqdn) | Fully qualified domain name for backend API |
| <a name="output_frontend_fqdn"></a> [frontend\_fqdn](#output\_frontend\_fqdn) | Fully qualified domain name for frontend dashboard |
| <a name="output_zone_id"></a> [zone\_id](#output\_zone\_id) | ID of the Route53 hosted zone |
| <a name="output_zone_name"></a> [zone\_name](#output\_zone\_name) | Name of the Route53 hosted zone |
| <a name="output_zone_name_servers"></a> [zone\_name\_servers](#output\_zone\_name\_servers) | Name servers for the hosted zone (if created) |
<!-- END_TF_DOCS -->
