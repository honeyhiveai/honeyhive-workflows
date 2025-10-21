# Karpenter Unit - Kubernetes node autoscaling

include "root" {
  path   = find_in_parent_folders("includes/stack-config.hcl")
  expose = true
}

# Dependencies for execution order - karpenter needs cluster to be ready
dependencies {
  paths = [
    "../cluster"
  ]
}

# Mock outputs for cluster dependency (needed for first deployment)
dependency "cluster" {
  config_path = "../cluster"

  # No mock outputs - Karpenter will only run when cluster actually exists

  # Skip outputs during destroy to avoid dependency issues
  skip_outputs = false
}

terraform {
  source = "git::https://github.com/honeyhiveai/honeyhive-terraform.git//hosting/aws/kubernetes/karpenter?ref=v1.2.14"
}

inputs = {
  # Core variables
  org            = include.root.locals.org
  env            = include.root.locals.env
  region         = include.root.locals.region
  sregion        = include.root.locals.sregion
  deployment     = include.root.locals.deployment
  aws_account_id = include.root.locals.account_id

  layer   = "hosting"
  service = "karpenter"

  # State bucket for remote state lookup
  state_bucket = try(include.root.locals.cfg.state_bucket, "honeyhive-federated-${include.root.locals.sregion}-state")

  # Cluster info - computed from config (dependency outputs don't work during destroy!)
  # cluster_name computes to: org-env-sregion-deployment
  cluster_name = "${include.root.locals.org}-${include.root.locals.env}-${include.root.locals.sregion}-${include.root.locals.deployment}"

  # Use dependency outputs - Karpenter will only run when cluster exists
  cluster_endpoint                  = dependency.cluster.outputs.cluster_endpoint
  cluster_certificate_authority_data = dependency.cluster.outputs.cluster_certificate_authority_data
  karpenter_node_role_arn           = dependency.cluster.outputs.karpenter_node_role_arn
  karpenter_node_role_name          = dependency.cluster.outputs.karpenter_node_role_name
  oidc_provider_arn                 = dependency.cluster.outputs.oidc_provider_arn
  ebs_csi_driver_role_arn           = dependency.cluster.outputs.ebs_csi_driver_role_arn

  # Karpenter configuration
  # Re-enabled now that cluster is clean
  deploy_karpenter_controller = try(include.root.locals.cfg.deploy_karpenter, true)
}

