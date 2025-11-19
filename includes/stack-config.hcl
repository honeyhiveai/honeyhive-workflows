# Flattened configuration for Terragrunt Stacks compatibility
# No nested includes - everything inline

locals {
  # Read tenant configuration
  # CONFIG_PATH from environment - may be absolute or relative
  config_path_raw = get_env("CONFIG_PATH", "")
  
  # Find workflow-repo root by locating the includes directory
  # get_parent_terragrunt_dir("includes") finds the directory containing "includes"
  workflow_repo_root = get_parent_terragrunt_dir("includes")
  
  # Construct absolute config path
  # The issue: get_env("CONFIG_PATH") returns relative path "../../../../config-repo/..."
  # even though CONFIG_PATH env var is set as absolute in workflow
  # This happens because Terragrunt reads env vars at parse time, before cd'ing into unit directory
  # Solution: Extract the actual file path from the relative path and prepend workflow-repo-root
  # Use split() to find "config-repo" and extract everything after it
  config_path_splits = split("config-repo", local.config_path_raw != "" ? local.config_path_raw : "")
  config_path = local.config_path_raw != "" ? (
    startswith(local.config_path_raw, "/") ? local.config_path_raw : (
      # Handle relative paths like "../../../../config-repo/honeyhive/usw2/federated-usw2-cp-dhruv.yaml"
      # Extract everything from "config-repo" onwards
      length(local.config_path_splits) > 1 ? "${local.workflow_repo_root}/config-repo${local.config_path_splits[1]}" : (
        # Fallback: try abspath with workflow_repo_root
        abspath("${local.workflow_repo_root}/${local.config_path_raw}")
      )
    )
  ) : "${local.workflow_repo_root}/config-repo/tenant.yaml"  # Fallback
  
  cfg = yamldecode(file(local.config_path))

  # Core parameters
  org        = local.cfg.org
  env        = local.cfg.env
  region     = local.cfg.region
  sregion    = local.cfg.sregion
  deployment = local.cfg.deployment
  account_id = local.cfg.account_id

  # Construct name prefix
  name_prefix = "${local.org}-${local.env}-${local.sregion}-${local.deployment}"

  # Features and configuration
  features      = try(local.cfg.features, {})
  terraform_ref = try(local.cfg.terraform_ref, get_env("TERRAFORM_REF", "v0.9.31"))

  # External ID for role assumption (use config value or generate from env)
  external_id = try(local.cfg.external_id, "honeyhive-deployments-${local.env}")

  # Common tags
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

# Remote state configuration
remote_state {
  backend = "s3"

  config = {
    bucket  = try(local.cfg.state_bucket, "honeyhive-federated-${local.sregion}-state")
    key     = "${local.org}/${local.env}/${local.sregion}/${local.deployment}/${basename(get_terragrunt_dir())}/terraform.tfstate"
    region  = local.region
    encrypt = true
    # DynamoDB locking disabled for dev/test (single user, isolated state files)
    # dynamodb_table = "honeyhive-orchestration-terraform-state-lock"
  }

  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
}

# AWS Provider configuration
generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"

  contents = <<EOF
provider "aws" {
  region = "${local.region}"
  
  assume_role {
    role_arn     = "arn:aws:iam::${local.account_id}:role/HoneyhiveProvisioner"
    session_name = "terragrunt-${local.env}-${local.deployment}"
    external_id  = "${local.external_id}"
  }
  
  allowed_account_ids = ["${local.account_id}"]
  
  default_tags {
    tags = {
      Organization = "${local.org}"
      Environment  = "${local.env}"
      Region       = "${local.region}"
      Deployment   = "${local.deployment}"
      ManagedBy    = "Terraform"
      Repository   = "https://github.com/honeyhiveai/honeyhive-workflows"
      Stack        = "terragrunt-stacks"
    }
  }
}
EOF
}


