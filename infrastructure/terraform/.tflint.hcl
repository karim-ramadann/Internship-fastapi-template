# TFLint config – run `tflint --init` once to install plugins
# https://github.com/terraform-linters/tflint

config {
  module     = true
  force      = false
  disabled_by_default = false
}

plugin "terraform" {
  enabled = true
  preset  = "recommended"
}

plugin "aws" {
  enabled = true
  version = "0.29.0"
  source  = "github.com/terraform-linters/tflint-ruleset-aws"
}
