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

terraform {
  source = "git::https://github.com/honeyhiveai/honeyhive-terraform.git//hosting/aws/kubernetes/karpenter?ref=v1.2.15"
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

  # Karpenter will read cluster info from remote state
  # No dependency outputs needed - module handles remote state lookup

  # Karpenter configuration
  # Re-enabled now that cluster is clean
  deploy_karpenter_controller = try(include.root.locals.cfg.deploy_karpenter, true)
}

