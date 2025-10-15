# EKS Cluster - Kubernetes control plane and managed node groups
# Depends on: VPC (for networking)

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
    vpc_cidr_block     = "10.0.0.0/16"
    private_subnet_ids = ["subnet-1", "subnet-2", "subnet-3"]
    dns_resolver_ip    = "10.0.0.2"
  }
  mock_outputs_merge_strategy_with_state = "shallow"
}

terraform {
  source = "git::https://github.com/honeyhiveai/honeyhive-terraform.git//hosting/aws/kubernetes/cluster?ref=v0.2.3"
}

inputs = merge(local.cfg, {
  environment = local.cfg.env  # Map env -> environment for Terraform modules
  layer              = "hosting"
  service            = "cluster"
  vpc_id             = dependency.vpc.outputs.vpc_id
  vpc_cidr_block     = dependency.vpc.outputs.vpc_cidr_block
  private_subnet_ids = dependency.vpc.outputs.private_subnet_ids
  dns_resolver_ip    = dependency.vpc.outputs.dns_resolver_ip
})

