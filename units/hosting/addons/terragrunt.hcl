# EKS Addons Unit - Cluster addons and controllers

include "root" {
  path   = find_in_parent_folders("includes/stack-config.hcl")
  expose = true
}

# Dependencies for execution order - addons need cluster and karpenter to be ready
dependencies {
  paths = [
    "../cluster",
    "../karpenter"
  ]
}

# Mock outputs for cluster dependency (needed for first deployment)
dependency "cluster" {
  config_path = "../cluster"

  # Mock outputs for first deployment when cluster doesn't exist yet
  mock_outputs = {
    cluster_name      = "${include.root.locals.org}-${include.root.locals.env}-${include.root.locals.sregion}-${include.root.locals.deployment}"
    cluster_endpoint  = "https://${include.root.locals.org}-${include.root.locals.env}-${include.root.locals.sregion}-${include.root.locals.deployment}.gr7.${include.root.locals.region}.eks.amazonaws.com"
    cluster_certificate_authority_data = "LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0t"
    oidc_provider_arn = "arn:aws:iam::${include.root.locals.account_id}:oidc-provider/oidc.eks.${include.root.locals.region}.amazonaws.com/id/00000000000000000000000000000000"
  }

  # Skip outputs during destroy to avoid dependency issues
  skip_outputs = false
}

terraform {
  source = "git::https://github.com/honeyhiveai/honeyhive-terraform.git//hosting/aws/kubernetes/addons?ref=${include.root.locals.terraform_ref}"
}

inputs = {
  # Core variables
  org        = include.root.locals.org
  env        = include.root.locals.env
  region     = include.root.locals.region
  sregion    = include.root.locals.sregion
  deployment = include.root.locals.deployment
  account_id = include.root.locals.account_id

  layer   = "hosting"
  service = "addons"

  # State bucket for remote state lookups (fallback only)
  state_bucket             = try(include.root.locals.cfg.state_bucket, "honeyhive-federated-${include.root.locals.sregion}-state")
  orchestration_account_id = try(include.root.locals.cfg.orchestration_account_id, "839515361289")

  # Cluster info - computed from config (dependency outputs don't work during destroy!)
  # cluster_name computes to: org-env-sregion-deployment
  cluster_name    = dependency.cluster.outputs.cluster_name
  cluster_version = try(include.root.locals.cfg.cluster_version, "1.32")

  # Use dependency outputs (with mock fallbacks for first deployment)
  cluster_endpoint  = dependency.cluster.outputs.cluster_endpoint
  cluster_certificate_authority_data = dependency.cluster.outputs.cluster_certificate_authority_data
  oidc_provider_arn = dependency.cluster.outputs.oidc_provider_arn

  # Don't pass these - module computes them from naming convention (eliminates chicken-and-egg)
  # iam_role_arns - computed as: arn:aws:iam::ACCOUNT:role/${iam_prefix}${RoleName}
  # karpenter_node_instance_profile_name - computed as: ${iam_prefix}KarpenterNode

  dns_zone_name = try(include.root.locals.cfg.dns_zone_name, null) # From config

  # Feature flags
  deploy_argocd       = try(include.root.locals.cfg.deploy_argocd, true)
  enable_karpenter    = try(include.root.locals.cfg.enable_karpenter, true)
  enable_monitoring   = try(include.root.locals.cfg.enable_monitoring, false)
  enable_external_dns = try(include.root.locals.cfg.enable_external_dns, false)
  enable_velero       = try(include.root.locals.cfg.enable_velero, false)
  enable_fluent_bit   = try(include.root.locals.cfg.enable_fluent_bit, false)

  # Configuration
  eso_namespace          = try(include.root.locals.cfg.eso_namespace, "external-secrets")
  node_instance_types    = try(include.root.locals.cfg.node_instance_types, ["m5.large", "m5.xlarge"])
  logging_retention_days = try(include.root.locals.cfg.logging_retention_days, 30)
}

