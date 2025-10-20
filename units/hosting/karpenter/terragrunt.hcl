# Karpenter Unit - Kubernetes node autoscaling

include "root" {
  path   = find_in_parent_folders("includes/stack-config.hcl")
  expose = true
}

dependency "cluster" {
  config_path = "../cluster"
  
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan"]
  mock_outputs = {
    cluster_name            = "mock-cluster"
    cluster_endpoint        = "https://mock-endpoint.eks.amazonaws.com"
    karpenter_node_role_arn = "arn:aws:iam::123456789012:role/MockKarpenterNodeRole"
    karpenter_node_role_name = "MockKarpenterNodeRole"
    oidc_provider_arn       = "arn:aws:iam::123456789012:oidc-provider/oidc.eks.us-west-2.amazonaws.com/id/MOCK"
  }
}

terraform {
  source = "git::https://github.com/honeyhiveai/honeyhive-terraform.git//hosting/aws/kubernetes/karpenter?ref=${include.root.locals.terraform_ref}"
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
  
  # Cluster outputs from dependency (to override remote state lookup)
  cluster_name            = dependency.cluster.outputs.cluster_name
  cluster_endpoint        = dependency.cluster.outputs.cluster_endpoint
  karpenter_node_role_arn = dependency.cluster.outputs.karpenter_node_role_arn
  karpenter_node_role_name = dependency.cluster.outputs.karpenter_node_role_name
  oidc_provider_arn       = dependency.cluster.outputs.oidc_provider_arn
  
  # Karpenter configuration
  # Temporarily disabled due to "cannot re-use a name" Helm conflict
  deploy_karpenter_controller = false  # try(include.root.locals.cfg.deploy_karpenter, true)
}

