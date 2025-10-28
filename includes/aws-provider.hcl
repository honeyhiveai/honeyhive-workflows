# Shared AWS provider configuration
# Generates provider configuration with proper role assumption

# Import tenant config to access variables
include "tenant_config" {
  path   = find_in_parent_folders("includes/tenant-config.hcl")
  expose = true
}

# Generate AWS provider configuration
generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"

  contents = <<EOF
provider "aws" {
  region = "${include.tenant_config.locals.region}"
  
  # Assume provisioner role in target account
  assume_role {
    role_arn     = "arn:aws:iam::${include.tenant_config.locals.account_id}:role/HoneyhiveProvisioner"
    session_name = "terragrunt-${include.tenant_config.locals.env}-${include.tenant_config.locals.deployment}-${basename(get_terragrunt_dir())}"
    external_id  = "honeyhive-deployments-${include.tenant_config.locals.env}"
  }
  
  # Prevent accidental cross-environment deployment
  allowed_account_ids = ["${include.tenant_config.locals.account_id}"]
  
  # Apply default tags to all resources
  default_tags {
    tags = ${jsonencode(include.tenant_config.locals.common_tags)}
  }
}

# Provider for accessing orchestration account resources (secrets, KMS)
provider "aws" {
  alias  = "orchestration"
  region = "${include.tenant_config.locals.region}"
  
  # No assume_role - uses existing OIDC/SSO credentials
  # which already have access to orchestration account
}
EOF
}
