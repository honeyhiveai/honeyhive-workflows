# EKS Cluster - Kubernetes control plane and managed node groups
# Depends on: VPC (for networking)

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
    key            = "${local.cfg.org}/${local.cfg.env}/${local.cfg.sregion}/${local.cfg.deployment}/hosting/cluster/tfstate.json"
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
  config_path = "../../substrate/vpc"

  mock_outputs = {
    vpc_id             = "vpc-00000000"
    vpc_cidr_block     = "10.0.0.0/16"
    private_subnet_ids = ["subnet-1", "subnet-2", "subnet-3"]
    dns_resolver_ip    = "10.0.0.2"
  }
  mock_outputs_merge_strategy_with_state = "shallow"
}

terraform {
  source = "git::https://github.com/honeyhiveai/honeyhive-terraform.git//hosting/aws/kubernetes/cluster?ref=v0.2.7"
}

inputs = merge(local.cfg, {
  layer              = "hosting"
  service            = "cluster"
  environment        = local.cfg.env        # Map env -> environment for Terraform modules
  aws_account_id     = local.cfg.account_id # Map account_id -> aws_account_id
  vpc_id             = dependency.vpc.outputs.vpc_id
  vpc_cidr_block     = dependency.vpc.outputs.vpc_cidr_block
  private_subnet_ids = dependency.vpc.outputs.private_subnet_ids
  dns_resolver_ip    = dependency.vpc.outputs.dns_resolver_ip
})

