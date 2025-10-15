# VPC - Foundation networking layer
# This is the first resource deployed in the substrate layer

include "root" {
  path = "${get_repo_root()}/overlays/aws/root.hcl"
}

locals {
  # Read tenant configuration from environment variable set by workflow
  cfg = yamldecode(file(get_env("TENANT_CONFIG_PATH")))
}

terraform {
  source = "git::https://github.com/honeyhiveai/honeyhive-terraform.git//substrate/aws/vpc?ref=v0.1.3"
}

# Merge tenant config with layer/service overrides
inputs = merge(local.cfg, {
  environment = local.cfg.env  # Map env -> environment for Terraform modules
  environment = local.cfg.env  # Map env -> environment for Terraform modules
  layer       = "substrate"
  service     = "vpc"
})

