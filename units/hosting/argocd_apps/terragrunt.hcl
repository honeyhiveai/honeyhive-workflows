# Terragrunt configuration for ArgoCD Applications

include "root" {
  path = find_in_parent_folders()
}

include "region" {
  path = "${dirname(find_in_parent_folders())}/aws/region.hcl"
}

include "env" {
  path = "${dirname(find_in_parent_folders())}/aws/env.hcl"
}

terraform {
  source = "${get_parent_terragrunt_dir()}/aws/kubernetes/argocd_apps"
}

dependencies {
  paths = [
    "../cluster",
    "../addons"
  ]
}

inputs = {
  # Core deployment parameters
  org         = local.cfg.org
  env         = local.cfg.env
  region      = local.cfg.region
  sregion     = local.cfg.sregion
  deployment  = local.cfg.deployment
  domain_name = local.cfg.domain_name

  # Cluster name for ArgoCD applications
  cluster_name = local.name_prefix

  # ArgoCD Applications configuration
  enable_argocd_applications = try(local.cfg.enable_argocd_applications, true)
  honeyhive_argocd_deploy_key = try(get_env("HONEYHIVE_ARGOCD_DEPLOY_KEY", ""), "")
  honeyhive_argocd_ref = try(local.cfg.honeyhive_argocd_ref, "main")
}
