# Flattened configuration for Terragrunt Stacks compatibility
# No nested includes - everything inline

locals {
  # Read tenant configuration from environment variable
  # Best Practice: CONFIG_PATH must be an absolute path set by the CI/CD workflow
  # This ensures the path is valid regardless of Terragrunt's working directory
  config_path = get_env("CONFIG_PATH", "")
  
  # Parse the YAML configuration
  # file() function works with absolute paths regardless of current working directory
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


