# ArgoCD Applications Unit - Data Stores App-of-Apps deployment

include "root" {
  path   = find_in_parent_folders("includes/stack-config.hcl")
  expose = true
}

terraform {
  source = "git::https://github.com/honeyhiveai/honeyhive-terraform.git//application/aws/kubernetes/argocd_apps?ref=${include.root.locals.terraform_ref}"
}

# Cross-stack dependency on hosting/cluster
# NOTE: Dependency block removed - Terragrunt Stacks cannot process cross-stack
# dependencies when paths don't exist locally. Module should read from remote state.
# For now, we'll pass explicit cluster values from the config or use null values

inputs = {
  # Core deployment parameters
  org        = include.root.locals.org
  env        = include.root.locals.env
  region     = include.root.locals.region
  sregion    = include.root.locals.sregion
  deployment = include.root.locals.deployment

  # Cluster information - computed from naming convention
  cluster_name                      = "${include.root.locals.org}-${include.root.locals.env}-${include.root.locals.sregion}-${include.root.locals.deployment}"
  cluster_endpoint                  = null  # Module will read from data source
  cluster_certificate_authority_data = null  # Module will read from data source

  # ArgoCD Application configuration
  enable_argocd_applications  = try(include.root.locals.cfg.enable_argocd_applications, true)
  honeyhive_argocd_deploy_key = try(get_env("HONEYHIVE_ARGOCD_DEPLOY_KEY", ""), "")
  honeyhive_helm_deploy_key   = try(get_env("HONEYHIVE_HELM_DEPLOY_KEY", ""), "")
  honeyhive_argocd_ref        = try(include.root.locals.cfg.honeyhive_argocd_ref, "main")
}

