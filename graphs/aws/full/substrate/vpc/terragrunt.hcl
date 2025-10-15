# VPC - Foundation networking layer
# This is the first resource deployed in the substrate layer

include "root" {
  path = "${get_repo_root()}/overlays/aws/root.hcl"
}

locals {
  # Read tenant configuration from environment variable set by workflow
  cfg = yamldecode(file(get_env("TENANT_CONFIG_PATH")))
}

# Remote state configuration for this service
remote_state {
  backend = "s3"
  config = {
    bucket         = try(local.cfg.state_bucket, "honeyhive-federated-${local.cfg.sregion}-state")
    key            = "${local.cfg.org}/${local.cfg.env}/${local.cfg.sregion}/${local.cfg.deployment}/substrate/vpc/tfstate.json"
    region         = local.cfg.region
    encrypt        = true
    dynamodb_table = "honeyhive-orchestration-terraform-state-lock"
  }
  
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite"
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

