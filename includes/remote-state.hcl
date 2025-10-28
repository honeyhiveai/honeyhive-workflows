# Shared remote state configuration
# Generates backend configuration for S3 state storage

# Import tenant config to access variables
include "tenant_config" {
  path   = find_in_parent_folders("includes/tenant-config.hcl")
  expose = true
}

# Generate remote state backend configuration
remote_state {
  backend = "s3"

  config = {
    # Use regional state bucket in orchestration account
    bucket = try(
      include.tenant_config.locals.cfg.state_bucket,
      "honeyhive-federated-${include.tenant_config.locals.sregion}-state"
    )

    # Hierarchical state key structure
    # Pattern: {org}/{env}/{sregion}/{deployment}/{stack}/{unit}/terraform.tfstate
    key = "${include.tenant_config.locals.org}/${include.tenant_config.locals.env}/${include.tenant_config.locals.sregion}/${include.tenant_config.locals.deployment}/${basename(get_terragrunt_dir())}/terraform.tfstate"

    # Regional configuration
    region  = include.tenant_config.locals.region
    encrypt = true

    # Shared lock table across all deployments
    dynamodb_table = "honeyhive-orchestration-terraform-state-lock"

    # Prevent concurrent modifications
    skip_bucket_versioning             = false
    skip_bucket_ssencryption           = false
    skip_bucket_root_access            = false
    skip_bucket_enforced_tls           = false
    skip_bucket_public_access_blocking = false
  }

  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
}
