# RDS Database - Application data persistence
# Depends on: VPC (for networking), Cluster (for connectivity)

include "root" {
  path = "${get_repo_root()}/overlays/aws/root.hcl"
}

locals {
  cfg = yamldecode(file(get_env("TENANT_CONFIG_PATH")))
}

# Skip if not deploying application layer
skip = try(get_env("DEPLOYMENT_LAYER") != "application" && get_env("DEPLOYMENT_LAYER") != "all", false)

# Remote state configuration for this service
remote_state {
  backend = "s3"
  config = {
    bucket         = try(local.cfg.state_bucket, "honeyhive-federated-${local.cfg.sregion}-state")
    key            = "${local.cfg.org}/${local.cfg.env}/${local.cfg.sregion}/${local.cfg.deployment}/application/database/tfstate.json"
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
  config_path = "${dirname(dirname(get_terragrunt_dir()))}/substrate/vpc"

  mock_outputs = {
    vpc_id             = "vpc-00000000"
    private_subnet_ids = ["subnet-1", "subnet-2", "subnet-3"]
  }
  mock_outputs_merge_strategy_with_state = "shallow"
}

dependency "cluster" {
  config_path = "${dirname(dirname(get_terragrunt_dir()))}/hosting/cluster"

  mock_outputs = {
    cluster_security_group_id = "sg-00000000"
  }
  mock_outputs_merge_strategy_with_state = "shallow"
}

terraform {
  source = "git::https://github.com/honeyhiveai/honeyhive-terraform.git//application/aws/database?ref=v0.2.7"
}

inputs = merge(local.cfg, {
  layer                     = "application"
  service                   = "database"
  vpc_id                    = dependency.vpc.outputs.vpc_id
  private_subnet_ids        = dependency.vpc.outputs.private_subnet_ids
  cluster_security_group_id = dependency.cluster.outputs.cluster_security_group_id
})

