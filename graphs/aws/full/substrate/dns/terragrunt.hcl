# DNS - Private Route53 hosted zones
# Depends on: VPC (for zone association)

include "root" {
  path = "${get_repo_root()}/overlays/aws/root.hcl"
}

locals {
  cfg = yamldecode(file(get_env("TENANT_CONFIG_PATH")))
}

# Remote state configuration for this service
remote_state {
  backend = "s3"
  config = {
    bucket         = try(local.cfg.state_bucket, "honeyhive-federated-${local.cfg.sregion}-state")
    key            = "${local.cfg.org}/${local.cfg.env}/${local.cfg.sregion}/${local.cfg.deployment}/substrate/dns/tfstate.json"
    region         = local.cfg.region
    encrypt        = true
    dynamodb_table = "honeyhive-orchestration-terraform-state-lock"
  }

  generate = {
    path      = "backend.tf"
    if_exists = "overwrite"
  }
}



dependency "vpc" {
  config_path = "${get_repo_root()}/graphs/aws/full/substrate/vpc"

  # Mock outputs for initial plan before VPC exists
  mock_outputs = {
    vpc_id = "vpc-00000000"
  }
  mock_outputs_merge_strategy_with_state = "shallow"
}

terraform {
  source = "git::https://github.com/honeyhiveai/honeyhive-terraform.git//substrate/aws/dns?ref=v0.2.7"
}

inputs = merge(local.cfg, {
  layer   = "substrate"
  service = "dns"
  vpc_id  = dependency.vpc.outputs.vpc_id
})

