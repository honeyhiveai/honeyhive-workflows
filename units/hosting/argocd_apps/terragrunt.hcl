# ArgoCD Applications Unit - GitOps application deployment

include "root" {
  path   = find_in_parent_folders("includes/stack-config.hcl")
  expose = true
}

terraform {
  source = "git::https://github.com/honeyhiveai/honeyhive-terraform.git//hosting/aws/kubernetes/argocd_apps?ref=${include.root.locals.terraform_ref}"
}

dependencies {
  paths = [
    "../cluster",
    "../addons"
  ]
}

inputs = {
  # Core deployment parameters
  org         = include.root.locals.org
  env         = include.root.locals.env
  region      = include.root.locals.region
  sregion     = include.root.locals.sregion
  deployment  = include.root.locals.deployment
  domain_name = try(include.root.locals.cfg.domain_name, "")

  # Cluster name for ArgoCD applications
  cluster_name = include.root.locals.name_prefix

  # ArgoCD Applications configuration
  enable_argocd_applications  = try(include.root.locals.cfg.enable_argocd_applications, true)
  honeyhive_argocd_deploy_key = try(get_env("HONEYHIVE_ARGOCD_DEPLOY_KEY", ""), "")
  honeyhive_argocd_ref        = try(include.root.locals.cfg.honeyhive_argocd_ref, "main")
}
