# AWS Terragrunt Overlay - Federated BYOC Model
# This overlay provides common configuration for all AWS-based Terragrunt stacks

locals {
  # Extract configuration from tenant.yaml
  cfg = yamldecode(file("${get_terragrunt_dir()}/tenant.yaml"))
  
  # Core variables from tenant configuration
  org        = local.cfg.org
  env        = local.cfg.env
  sregion    = local.cfg.sregion
  region     = local.cfg.region
  deployment = local.cfg.deployment
  layer      = local.cfg.layer
  service    = local.cfg.service
  
  # Common tags to apply to all resources
  common_tags = merge(
    {
      Owner        = "honeyhive"
      Organization = local.org
      Environment  = local.env
      Region       = local.region
      Deployment   = local.deployment
      Service      = local.service
      Layer        = local.layer
      ManagedBy    = "Terraform"
      Repository   = "https://github.com/honeyhiveai/honeyhive-terraform.git"
    },
    try(local.cfg.tags, {})
  )
  
  # State bucket configuration - allow override for BYOC
  state_bucket = try(local.cfg.state_bucket, "honeyhive-federated-${local.sregion}-state")
  
  # State key pattern - MUST match the specified format
  state_key = "${local.org}/${local.env}/${local.sregion}/${local.deployment}/${local.layer}/${local.service}/tfstate.json"
  
  # Valid short region codes
  valid_regions = ["use1", "usw2", "euw1", "euc1", "apse4", "apse2"]
  
  # AWS account ID (optional, for validation)
  account_id = try(local.cfg.account_id, "")
}

# Generate AWS provider configuration
generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite"
  contents  = <<-EOF
    provider "aws" {
      region = "${local.region}"
      
      %{ if local.account_id != "" ~}
      allowed_account_ids = ["${local.account_id}"]
      %{ endif ~}
      
      default_tags {
        tags = ${jsonencode(local.common_tags)}
      }
    }
  EOF
}

# Configure remote state backend
remote_state {
  backend = "s3"
  config = {
    bucket         = local.state_bucket
    key            = local.state_key
    region         = local.region
    encrypt        = true
    dynamodb_table = "terraform-state-lock"
  }
  
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite"
  }
}

# Terraform version constraints
terraform_version_constraint = ">= 1.9.0"
terragrunt_version_constraint = ">= 0.66.0"

# Prevent running Terragrunt in the wrong directory
prevent_destroy = false

# Skip outputs that don't exist
skip_outputs = true

# Retry configuration for transient errors
retry_configuration {
  retry_on_errors = [
    "(?s).*Error creating.*: ResourceInUseException.*",
    "(?s).*Error creating.*: ThrottlingException.*",
    "(?s).*Error creating.*: RequestLimitExceeded.*"
  ]
  max_retry_attempts = 3
  retry_sleep_base_seconds = 5
}

# Input validation
terraform {
  before_hook "validate_region" {
    commands = ["plan", "apply", "destroy"]
    execute  = ["bash", "-c", <<-SCRIPT
      SREGION="${local.sregion}"
      VALID_REGIONS="${join(" ", local.valid_regions)}"
      
      if [[ ! -z "$SREGION" ]] && [[ ! " $VALID_REGIONS " =~ " $SREGION " ]]; then
        echo "Warning: Region '$SREGION' is not in the list of known regions: $VALID_REGIONS"
        echo "Continuing anyway (this might be a new region or stub)..."
      fi
    SCRIPT
    ]
  }
}
