# Pod Identities - IAM roles for Kubernetes pods
# Depends on: EKS Cluster (for OIDC provider)

include "root" {
  path = "${get_repo_root()}/overlays/aws/root.hcl"
}

locals {
  cfg = yamldecode(file(get_env("TENANT_CONFIG_PATH")))
}

# Skip if deploying substrate only
skip = try(get_env("DEPLOYMENT_LAYER") == "substrate", false)

# Remote state configuration for this service
remote_state {
  backend = "s3"
  config = {
    bucket         = try(local.cfg.state_bucket, "honeyhive-federated-${local.cfg.sregion}-state")
    key            = "${local.cfg.org}/${local.cfg.env}/${local.cfg.sregion}/${local.cfg.deployment}/hosting/pod_identities/tfstate.json"
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
  config_path = "${dirname(get_terragrunt_dir())}/cluster"

  mock_outputs = {
    cluster_name      = "mock-cluster"
    oidc_provider_arn = "arn:aws:iam::123456789012:oidc-provider/mock"
    oidc_provider     = "oidc.eks.us-west-2.amazonaws.com/id/MOCK"
  }
  mock_outputs_merge_strategy_with_state = "shallow"
}

terraform {
  source = "git::https://github.com/honeyhiveai/honeyhive-terraform.git//hosting/aws/pod_identities?ref=v0.2.7"
}

inputs = merge(local.cfg, {
  layer             = "hosting"
  service           = "pod_identities"
  cluster_name      = dependency.cluster.outputs.cluster_name
  oidc_provider_arn = dependency.cluster.outputs.oidc_provider_arn
  oidc_provider     = dependency.cluster.outputs.oidc_provider
})

