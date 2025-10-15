# RDS Database - Application data persistence
# Depends on: VPC (for networking), Cluster (for connectivity)

include "root" {
  path = "${get_repo_root()}/overlays/aws/root.hcl"
}

locals {
  cfg = yamldecode(file(get_env("TENANT_CONFIG_PATH")))
}

dependency "vpc" {
  config_path = "${get_repo_root()}/graphs/aws/full/substrate/vpc"
  
  mock_outputs = {
    vpc_id             = "vpc-00000000"
    private_subnet_ids = ["subnet-1", "subnet-2", "subnet-3"]
  }
  mock_outputs_merge_strategy_with_state = "shallow"
}

dependency "cluster" {
  config_path = "${get_repo_root()}/graphs/aws/full/hosting/cluster"
  
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

