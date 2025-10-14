# Twingate VPN - Optional secure access
# Depends on: VPC (for networking)
# Optional: Deployed based on deployment_type and features.twingate

include "root" {
  path = "${get_repo_root()}/overlays/aws/root.hcl"
}

locals {
  cfg = yamldecode(file(get_env("TENANT_CONFIG_PATH")))
}

# Skip if:
# 1. Not included in deployment type's substrate_services list, OR
# 2. features.twingate explicitly disabled
skip = !(contains(include.root.locals.current_deployment.substrate_services, "twingate") && try(local.cfg.features.twingate, true))

dependency "vpc" {
  config_path = "${get_repo_root()}/graphs/aws/full/substrate/vpc"
  
  mock_outputs = {
    vpc_id             = "vpc-00000000"
    private_subnet_ids = ["subnet-1", "subnet-2", "subnet-3"]
  }
  mock_outputs_merge_strategy_with_state = "shallow"
}

terraform {
  source = "git::https://github.com/honeyhiveai/honeyhive-terraform.git//substrate/aws/twingate?ref=v1.0.0"
}

inputs = merge(local.cfg, {
  layer              = "substrate"
  service            = "twingate"
  vpc_id             = dependency.vpc.outputs.vpc_id
  private_subnet_ids = dependency.vpc.outputs.private_subnet_ids
})

