# Flattened configuration for Terragrunt Stacks compatibility
# No nested includes - everything inline

locals {
  # Read tenant configuration
  config_path = get_env("CONFIG_PATH")
  cfg                = yamldecode(file(local.config_path))

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
  terraform_ref = try(local.cfg.terraform_ref, get_env("TERRAFORM_REF", "v0.2.15"))

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
    key     = "${local.org}/${local.env}/${local.sregion}/${local.deployment}/${path_relative_to_include()}/terraform.tfstate"
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
    external_id  = "honeyhive-deployments-${local.env}"
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


