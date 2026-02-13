/**
 * # SES Module
 *
 * Thin wrapper around [terraform-aws-modules/ses/aws](https://registry.terraform.io/modules/terraform-aws-modules/ses/aws/latest).
 *
 * Standards enforced:
 * - Naming convention for configuration set: `{project}-{environment}`
 * - Domain identity verification via Route53
 * - DKIM signing enabled by default
 * - MAIL FROM domain configuration
 * - Standard tagging
 */

locals {
  tags = merge(
    var.context.common_tags,
    {
      Name      = "${var.context.project}-ses-${var.context.environment}"
      Component = "ses"
    },
    var.tags
  )
}

module "ses" {
  source  = "terraform-aws-modules/ses/aws"
  version = "~> 1.0"

  # Domain identity
  domain        = var.domain
  zone_id       = var.route53_zone_id
  verify_domain = var.verify_domain
  verify_dkim   = var.verify_dkim

  # Configuration set
  configuration_set_name   = "${var.context.project}-${var.context.environment}"
  create_configuration_set = var.create_configuration_set

  # MAIL FROM
  mail_from_domain = var.mail_from_subdomain != "" ? "${var.mail_from_subdomain}.${var.domain}" : null

  # Email identities (individual email addresses)
  email_identities = var.email_identities

  # Templates
  templates = var.templates

  tags = local.tags
}
