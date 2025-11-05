# ArgoCD Applications Unit - honeyhive-apps deployment (moved from hosting/)

include "root" {
  path   = find_in_parent_folders("includes/stack-config.hcl")
  expose = true
}

# Note: Cross-stack dependencies for sequencing are handled by full.stack.yaml
# When running standalone application stack, cluster information is read from remote state
# The module's remote state lookup will handle fetching cluster outputs from hosting/cluster

terraform {
  source = "git::https://github.com/honeyhiveai/honeyhive-terraform.git//application/aws/kubernetes/argocd_apps?ref=${include.root.locals.terraform_ref}"
}

# Cross-stack dependency on hosting/cluster
# NOTE: Dependency block removed - Terragrunt Stacks cannot process cross-stack
# dependencies when paths don't exist locally. Module reads cluster outputs from remote state
# when cluster_endpoint is not provided as input.

# Dependency on secrets_configs for IAM roles and ECR URLs
dependency "secrets_configs" {
  config_path = "../secrets_configs"

  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan"]
  mock_outputs = {
    database_password_secret_name = null
    ecr_repository_urls           = {}
    iam_role_arns                 = {}
  }

  skip_outputs = false
}

# State bucket for remote state lookup (cross-stack dependency)
# Note: secrets_configs dependency is used, but we also provide state_bucket
# as a fallback for remote state lookups if dependency is skipped

inputs = {
  # Core deployment parameters
  org        = include.root.locals.org
  env        = include.root.locals.env
  region     = include.root.locals.region
  sregion    = include.root.locals.sregion
  deployment = include.root.locals.deployment
  domain_name = try(include.root.locals.cfg.domain_name, "")
  deployment_type = try(include.root.locals.cfg.deployment_type, "full_stack")

  # Cluster information - module reads from remote state if not provided
  # For standalone application stack runs, cluster info comes from remote state
  # For full stack runs, cluster info would come from dependency (but we removed it)
  # Module will compute cluster name from naming convention if not provided
  cluster_name                      = "${include.root.locals.org}-${include.root.locals.env}-${include.root.locals.sregion}-${include.root.locals.deployment}"
  cluster_endpoint                  = null  # Module will read from remote state
  cluster_certificate_authority_data = null  # Module will read from remote state

  # ArgoCD Application configuration
  enable_argocd_applications  = try(include.root.locals.cfg.enable_argocd_applications, true)
  honeyhive_argocd_deploy_key = try(get_env("HONEYHIVE_ARGOCD_DEPLOY_KEY", ""), "")
  honeyhive_helm_deploy_key   = try(get_env("HONEYHIVE_HELM_DEPLOY_KEY", ""), "")
  honeyhive_argocd_ref        = try(include.root.locals.cfg.honeyhive_argocd_ref, "main")

  # Secrets and configs from dependency
  secrets_configs = {
    database_password_secret_name = try(dependency.secrets_configs.outputs.database_password_secret_name, null)
    ecr_repository_urls           = try(dependency.secrets_configs.outputs.ecr_repository_urls, {})
    iam_role_arns                 = try(dependency.secrets_configs.outputs.iam_role_arns, {})
  }

  # State bucket for remote state lookup (fallback)
  state_bucket = try(include.root.locals.cfg.state_bucket, "honeyhive-federated-${include.root.locals.sregion}-state")
}

