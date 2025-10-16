# Shared tenant configuration loader
# This include provides access to tenant YAML configuration

locals {
  # Read tenant configuration from environment variable set by workflow
  # This is the single source of truth for all configuration
  tenant_config_path = get_env("TENANT_CONFIG_PATH")
  
  # Parse the YAML configuration
  cfg = yamldecode(file(local.tenant_config_path))
  
  # Extract commonly used values for convenience
  org         = local.cfg.org
  env         = local.cfg.env
  region      = local.cfg.region
  sregion     = local.cfg.sregion
  deployment  = local.cfg.deployment
  account_id  = local.cfg.account_id
  
  # Construct name prefix used across all resources
  name_prefix = "${local.org}-${local.env}-${local.sregion}-${local.deployment}"
  
  # Extract features with defaults
  features = try(local.cfg.features, {})
  
  # Terraform module version to use
  terraform_ref = try(local.cfg.terraform_ref, "v0.2.7")
  
  # Common tags applied to all resources
  common_tags = {
    Organization = local.org
    Environment  = local.env
    Region       = local.region
    Deployment   = local.deployment
    ManagedBy    = "Terraform"
    Repository   = "https://github.com/honeyhiveai/honeyhive-workflows"
    Stack        = "terragrunt-stacks"
  }
}
