# AWS Terragrunt Overlay - Federated BYOC Model
# This overlay provides common configuration for all AWS-based Terragrunt stacks
#
# DEPLOYMENT TYPES & FEATURE DEFAULTS
# ------------------------------------
# Each deployment_type provides intelligent defaults for features, reducing configuration
# overhead while allowing per-tenant customization for edge cases.
#
# Example:
#   deployment_type: full_stack
#   # Automatically enables: twingate, karpenter, external_secrets, alb_controller, observability
#
#   features:
#     twingate: false  # Override: disable Twingate for this specific tenant
#
# This pattern is enterprise-grade: opinionated defaults with escape hatches.

locals {
  # Extract configuration from tenant.yaml (via env var or local file)
  cfg = yamldecode(file(try(get_env("TENANT_CONFIG_PATH"), "${get_terragrunt_dir()}/tenant.yaml")))

  # Core variables from tenant configuration
  org             = local.cfg.org
  env             = local.cfg.env
  sregion         = local.cfg.sregion
  region          = local.cfg.region
  deployment      = local.cfg.deployment
  deployment_type = try(local.cfg.deployment_type, "full_stack")

  # DEPLOYMENT TYPE CONFIGURATION MATRIX
  # Defines which services and features are included in each deployment type
  deployment_config = {
    "full_stack" = {
      substrate_services   = ["vpc", "dns", "twingate"]
      hosting_services     = ["cluster", "karpenter", "pod_identities", "addons"]
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
      substrate_services   = ["vpc", "dns"]
      hosting_services     = ["cluster", "pod_identities", "addons"]
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
      substrate_services   = ["vpc", "dns"]
      hosting_services     = ["cluster", "karpenter", "addons"]
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
      substrate_services   = ["vpc", "dns"]
      hosting_services     = ["cluster", "addons"]
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

  # Merge deployment type default features with user-provided overrides
  # This allows deployment types to set intelligent defaults while permitting per-tenant customization
  features = merge(
    local.current_deployment.default_features,
    try(local.cfg.features, {})
  )

  # Common tags to apply to all resources
  # Layer and Service tags are set by graph nodes via inputs
  common_tags = merge(
    {
      Owner        = "honeyhive"
      Organization = local.org
      Environment  = local.env
      Region       = local.region
      Deployment   = local.deployment
      ManagedBy    = "Terraform"
      Repository   = "https://github.com/honeyhiveai/honeyhive-terraform.git"
    },
    try(local.cfg.tags, {})
  )

  # State bucket configuration - allow override for BYOC
  state_bucket = try(local.cfg.state_bucket, "honeyhive-federated-${local.sregion}-state")

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

# Remote state is defined by each graph node with its specific key
# Overlay provides state_bucket for graph nodes to use

# Terraform version constraints
terraform_version_constraint  = ">= 1.9.0"
terragrunt_version_constraint = ">= 0.66.0"

# Prevent running Terragrunt in the wrong directory
prevent_destroy = false

# Input validation
terraform {
  before_hook "validate_region" {
    commands = ["plan", "apply", "destroy"]
    execute = ["bash", "-c", <<-SCRIPT
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
