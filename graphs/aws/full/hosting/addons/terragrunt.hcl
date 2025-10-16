# EKS Addons - Core cluster components (CoreDNS, metrics-server, ALB controller, ESO, etc.)
# Depends on: Cluster, Karpenter (Karpenter must provision nodes first)

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
    key            = "${local.cfg.org}/${local.cfg.env}/${local.cfg.sregion}/${local.cfg.deployment}/hosting/addons/tfstate.json"
    region         = local.cfg.region
    encrypt        = true
    dynamodb_table = "honeyhive-orchestration-terraform-state-lock"
  }

  generate = {
    path      = "backend.tf"
    if_exists = "overwrite"
  }
}



dependency "cluster" {
  config_path = "${get_repo_root()}/graphs/aws/full/hosting/cluster"

  mock_outputs = {
    cluster_name                       = "mock-cluster"
    cluster_endpoint                   = "https://mock.eks.amazonaws.com"
    cluster_version                    = "1.29"
    oidc_provider_arn                  = "arn:aws:iam::123456789012:oidc-provider/mock"
    cluster_certificate_authority_data = "LS0tLS1=="
  }
  mock_outputs_merge_strategy_with_state = "shallow"
}

dependency "karpenter" {
  config_path  = "${get_repo_root()}/graphs/aws/full/hosting/karpenter"
  skip_outputs = try(!include.root.locals.features.karpenter, false)

  mock_outputs = {
    karpenter_node_class_name = "default"
  }
  mock_outputs_merge_strategy_with_state = "shallow"
}

terraform {
  source = "git::https://github.com/honeyhiveai/honeyhive-terraform.git//hosting/aws/kubernetes/addons?ref=v0.2.7"
}

inputs = merge(local.cfg, {
  layer                              = "hosting"
  service                            = "addons"
  cluster_name                       = dependency.cluster.outputs.cluster_name
  cluster_endpoint                   = dependency.cluster.outputs.cluster_endpoint
  cluster_version                    = dependency.cluster.outputs.cluster_version
  oidc_provider_arn                  = dependency.cluster.outputs.oidc_provider_arn
  cluster_certificate_authority_data = dependency.cluster.outputs.cluster_certificate_authority_data
})

