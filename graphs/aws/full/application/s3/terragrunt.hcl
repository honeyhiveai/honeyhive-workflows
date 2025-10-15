# S3 Buckets - Application storage
# Depends on: Cluster (for pod identity access policies)

include "root" {
  path = "${get_repo_root()}/overlays/aws/root.hcl"
}

locals {
  cfg = yamldecode(file(get_env("TENANT_CONFIG_PATH")))
}
  
  # Define layer and service for this graph node (used in state key)
  layer   = local.layer
  service = local.service

dependency "cluster" {
  config_path = "${get_repo_root()}/graphs/aws/full/hosting/cluster"
  
  mock_outputs = {
    cluster_name      = "mock-cluster"
    oidc_provider_arn = "arn:aws:iam::123456789012:oidc-provider/mock"
  }
  mock_outputs_merge_strategy_with_state = "shallow"
}

terraform {
  source = "git::https://github.com/honeyhiveai/honeyhive-terraform.git//application/aws/s3?ref=v0.2.7"
}

inputs = merge(local.cfg, {
  layer   = local.layer
  service = local.service
  cluster_name      = dependency.cluster.outputs.cluster_name
  oidc_provider_arn = dependency.cluster.outputs.oidc_provider_arn
})

