# Karpenter - Kubernetes node autoscaling
# Depends on: EKS Cluster (for OIDC provider, cluster name)
# Optional: Deployed based on deployment_type and features.karpenter

include "root" {
  path = "${get_repo_root()}/overlays/aws/root.hcl"
}

locals {
  cfg = yamldecode(file(get_env("TENANT_CONFIG_PATH")))
}

# Skip if karpenter feature is disabled
# Deployment type defaults are documented but skip uses simple feature flag check
skip = !try(local.cfg.features.karpenter, true)

dependency "cluster" {
  config_path = "${get_repo_root()}/graphs/aws/full/hosting/cluster"
  
  mock_outputs = {
    cluster_name              = "mock-cluster"
    cluster_endpoint          = "https://mock.eks.amazonaws.com"
    cluster_version           = "1.29"
    oidc_provider_arn         = "arn:aws:iam::123456789012:oidc-provider/mock"
    oidc_provider             = "oidc.eks.us-west-2.amazonaws.com/id/MOCK"
    cluster_certificate_authority_data = "LS0tLS1=="
  }
  mock_outputs_merge_strategy_with_state = "shallow"
}

terraform {
  source = "git::https://github.com/honeyhiveai/honeyhive-terraform.git//hosting/aws/kubernetes/karpenter?ref=v0.2.3"
}

inputs = merge(local.cfg, {
  environment = local.cfg.env  # Map env -> environment for Terraform modules
  layer                              = "hosting"
  service                            = "karpenter"
  cluster_name                       = dependency.cluster.outputs.cluster_name
  cluster_endpoint                   = dependency.cluster.outputs.cluster_endpoint
  cluster_version                    = dependency.cluster.outputs.cluster_version
  oidc_provider_arn                  = dependency.cluster.outputs.oidc_provider_arn
  oidc_provider                      = dependency.cluster.outputs.oidc_provider
  cluster_certificate_authority_data = dependency.cluster.outputs.cluster_certificate_authority_data
})

