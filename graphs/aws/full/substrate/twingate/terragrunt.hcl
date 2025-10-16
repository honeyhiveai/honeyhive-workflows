# Twingate VPN - Optional secure access
# Depends on: VPC (for networking)
# Optional: Deployed based on deployment_type and features.twingate

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
    key            = "${local.cfg.org}/${local.cfg.env}/${local.cfg.sregion}/${local.cfg.deployment}/substrate/twingate/tfstate.json"
    region         = local.cfg.region
    encrypt        = true
    dynamodb_table = "honeyhive-orchestration-terraform-state-lock"
  }

  generate = {
    path      = "backend.tf"
    if_exists = "overwrite"
  }
}



# Skip if twingate feature is disabled
# Uses merged features from overlay (deployment type defaults + user overrides)
skip = !try(include.root.locals.features.twingate, false)

dependency "vpc" {
  config_path = "${get_repo_root()}/graphs/aws/full/substrate/vpc"

  mock_outputs = {
    vpc_id             = "vpc-00000000"
    private_subnet_ids = ["subnet-1", "subnet-2", "subnet-3"]
  }
  mock_outputs_merge_strategy_with_state = "shallow"
}

terraform {
  source = "git::https://github.com/honeyhiveai/honeyhive-terraform.git//substrate/aws/twingate?ref=v0.2.7"
}

inputs = merge(local.cfg, {
  layer              = "substrate"
  service            = "twingate"
  vpc_id             = dependency.vpc.outputs.vpc_id
  private_subnet_ids = dependency.vpc.outputs.private_subnet_ids
})

