# VPC - Foundation networking layer
# This is the first resource deployed in the substrate layer

include "root" {
  path = "${get_repo_root()}/overlays/aws/root.hcl"
}

locals {
  # Read tenant configuration from environment variable set by workflow
  cfg = yamldecode(file(get_env("TENANT_CONFIG_PATH")))
}

# Override remote_state key for this specific service
remote_state {
  config = {
    key = "${local.cfg.org}/${local.cfg.env}/${local.cfg.sregion}/${local.cfg.deployment}/substrate/vpc/tfstate.json"
  }
}

terraform {
  source = "git::https://github.com/honeyhiveai/honeyhive-terraform.git//substrate/aws/vpc?ref=v0.2.7"
}

# Merge tenant config with layer/service overrides
inputs = merge(local.cfg, {
  layer   = "substrate"
  service = "vpc"
})

