# AWS Terragrunt Overlay - Federated BYOC Model
# This overlay provides common configuration for all AWS-based Terragrunt stacks

locals {
  # Extract configuration from tenant.yaml (via env var or local file)
  cfg = yamldecode(file(try(get_env("TENANT_CONFIG_PATH"), "${get_terragrunt_dir()}/tenant.yaml")))
  
  # Core variables from tenant configuration
  org             = local.cfg.org
  env             = local.cfg.env
  sregion         = local.cfg.sregion
  region          = local.cfg.region
  deployment      = local.cfg.deployment
  layer           = try(local.layer, "unknown")  # Inherited from graph node locals
  service         = try(local.service, "unknown")  # Inherited from graph node locals
  deployment_type = try(local.cfg.deployment_type, "full_stack")
  
  # DEPLOYMENT TYPE CONFIGURATION MATRIX
  # Defines which services and features are included in each deployment type
  deployment_config = {
    "full_stack" = {
      substrate_services  = ["vpc", "dns", "twingate"]
      hosting_services    = ["cluster", "karpenter", "pod_identities", "addons"]
      application_services = ["database", "s3"]
      default_features = {
        karpenter                    = true
        external_secrets             = true
        aws_load_balancer_controller = true
        twingate                     = true
        observability                = true
      }
      description = "Complete platform deployment (control plane + data plane + ops)"
    }
    
    "control_plane" = {
      substrate_services  = ["vpc", "dns"]
      hosting_services    = ["cluster", "pod_identities", "addons"]
      application_services = []
      default_features = {
        karpenter                    = false
        external_secrets             = true
        aws_load_balancer_controller = true
        twingate                     = false
        observability                = true
      }
      description = "Control plane only (API, dashboard, GitOps)"
    }
    
    "data_plane" = {
      substrate_services  = ["vpc", "dns"]
      hosting_services    = ["cluster", "karpenter", "addons"]
      application_services = []
      default_features = {
        karpenter                    = true
        external_secrets             = false
        aws_load_balancer_controller = true
        twingate                     = false
        observability                = false
      }
      description = "Data plane only (compute workloads, minimal features)"
    }
    
    "customer" = {
      substrate_services  = ["vpc", "dns"]
      hosting_services    = ["cluster", "addons"]
      application_services = []
      default_features = {
        karpenter                    = false
        external_secrets             = true
        aws_load_balancer_controller = true
        twingate                     = false
        observability                = false
      }
      description = "LEGACY: Basic customer deployment"
    }
  }
  
  # Helper: Check if a service should be deployed based on deployment type
  current_deployment = try(local.deployment_config[local.deployment_type], local.deployment_config["full_stack"])
  
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
      
      assume_role {
        role_arn     = "arn:aws:iam::${local.account_id}:role/HoneyhiveProvisioner"
        session_name = "terragrunt-${local.env}-${local.deployment}"
        external_id  = "honeyhive-deployments-${local.env}"
      }
      
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
    dynamodb_table = "honeyhive-orchestration-terraform-state-lock"
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
