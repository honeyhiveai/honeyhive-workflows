# EKS Addons Unit - Cluster addons and controllers

include "root" {
  path   = find_in_parent_folders("includes/stack-config.hcl")
  expose = true
}

dependency "cluster" {
  config_path = "../cluster"
  
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan"]
  mock_outputs = {
    cluster_name      = "mock-cluster"
    cluster_endpoint  = "https://mock-endpoint.eks.amazonaws.com"
    cluster_version   = "1.32"
    oidc_provider_arn = "arn:aws:iam::123456789012:oidc-provider/oidc.eks.us-west-2.amazonaws.com/id/MOCK"
  }
}

dependency "karpenter" {
  config_path = "../karpenter"
  
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan"]
  mock_outputs = {
    karpenter_queue_name = "mock-karpenter-queue"
  }
}

terraform {
  source = "git::https://github.com/honeyhiveai/honeyhive-terraform.git//hosting/aws/kubernetes/addons?ref=${include.root.locals.terraform_ref}"
}

inputs = {
  # Core variables
  org            = include.root.locals.org
  env            = include.root.locals.env
  region         = include.root.locals.region
  sregion        = include.root.locals.sregion
  deployment     = include.root.locals.deployment
  account_id     = include.root.locals.account_id
  
  layer   = "hosting"
  service = "addons"
  
  # State bucket for remote state lookups
  state_bucket                = try(include.root.locals.cfg.state_bucket, "honeyhive-federated-${include.root.locals.sregion}-state")
  orchestration_account_id    = try(include.root.locals.cfg.orchestration_account_id, "839515361289")
  
  # Feature flags
  deploy_argocd               = try(include.root.locals.cfg.deploy_argocd, true)
  enable_karpenter            = try(include.root.locals.cfg.enable_karpenter, true)
  enable_monitoring           = try(include.root.locals.cfg.enable_monitoring, false)
  enable_external_dns         = try(include.root.locals.cfg.enable_external_dns, false)
  enable_velero               = try(include.root.locals.cfg.enable_velero, false)
  enable_fluent_bit           = try(include.root.locals.cfg.enable_fluent_bit, false)
  
  # Configuration
  eso_namespace               = try(include.root.locals.cfg.eso_namespace, "external-secrets")
  node_instance_types         = try(include.root.locals.cfg.node_instance_types, ["m5.large", "m5.xlarge"])
  logging_retention_days      = try(include.root.locals.cfg.logging_retention_days, 30)
}

