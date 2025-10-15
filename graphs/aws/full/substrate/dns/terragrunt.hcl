# DNS - Private Route53 hosted zones
# Depends on: VPC (for zone association)

include "root" {
  path = "${get_repo_root()}/overlays/aws/root.hcl"
}

locals {
  cfg = yamldecode(file(get_env("TENANT_CONFIG_PATH")))
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
  source = "git::https://github.com/honeyhiveai/honeyhive-terraform.git//substrate/aws/dns?ref=v0.1.3"
}

inputs = merge(local.cfg, {
  layer   = "substrate"
  service = "dns"
  vpc_id  = dependency.vpc.outputs.vpc_id
})

