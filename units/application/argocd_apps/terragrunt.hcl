# ArgoCD Applications Unit - Data Stores App-of-Apps deployment

include "root" {
  path   = find_in_parent_folders("includes/stack-config.hcl")
  expose = true
}

terraform {
  source = "git::https://github.com/honeyhiveai/honeyhive-terraform.git//application/aws/kubernetes/argocd_apps?ref=${include.root.locals.terraform_ref}"
}

# Cross-stack dependency on hosting/cluster
# NOTE: Cannot use direct dependency path as it's in a different stack
# Instead, compute cluster info from naming convention and let Terraform module
# read from AWS data sources. The module will handle null values gracefully.
inputs = {
  # Core deployment parameters
  org        = include.root.locals.org
  env        = include.root.locals.env
  region     = include.root.locals.region
  sregion    = include.root.locals.sregion
  deployment = include.root.locals.deployment

  # Cluster information - computed from naming convention
  # Module will read actual values from AWS EKS data source if cluster_endpoint is null
  cluster_name                      = "${include.root.locals.org}-${include.root.locals.env}-${include.root.locals.sregion}-${include.root.locals.deployment}"
  cluster_endpoint                  = try(include.root.locals.cfg.cluster_endpoint, null)
  cluster_certificate_authority_data = try(include.root.locals.cfg.cluster_certificate_authority_data, null)

  # ArgoCD Application configuration
  enable_argocd_applications  = try(include.root.locals.cfg.enable_argocd_applications, true)
  honeyhive_argocd_deploy_key = try(get_env("HONEYHIVE_ARGOCD_DEPLOY_KEY", ""), "")
  honeyhive_helm_deploy_key   = try(get_env("HONEYHIVE_HELM_DEPLOY_KEY", ""), "")
  honeyhive_argocd_ref        = try(include.root.locals.cfg.honeyhive_argocd_ref, "main")
}

