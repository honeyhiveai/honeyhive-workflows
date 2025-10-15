# VPC - Foundation networking layer
# This is the first resource deployed in the substrate layer

include "root" {
  path = "${get_repo_root()}/overlays/aws/root.hcl"
}

locals {
  # Read tenant configuration from environment variable set by workflow
  cfg = yamldecode(file(get_env("TENANT_CONFIG_PATH")))
  
  # Define layer and service for this graph node (used in state key)
  layer   = "substrate"
  service = "vpc"
}

terraform {
  source = "git::https://github.com/honeyhiveai/honeyhive-terraform.git//substrate/aws/vpc?ref=v0.2.7"
}

# Merge tenant config with layer/service overrides
inputs = merge(local.cfg, {
  layer   = local.layer
  service = local.service
})

