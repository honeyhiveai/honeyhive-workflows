# Azure Terragrunt Overlay - Stub Implementation
# This is a placeholder for future Azure support

locals {
  # Extract configuration from tenant.yaml
  cfg = yamldecode(file("${get_terragrunt_dir()}/tenant.yaml"))
  
  # Core variables from tenant configuration
  org        = local.cfg.org
  env        = local.cfg.env
  sregion    = local.cfg.sregion
  region     = try(local.cfg.region, "eastus")
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
}

# Generate Azure provider configuration
generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite"
  contents  = <<-EOF
    terraform {
      required_providers {
        azurerm = {
          source  = "hashicorp/azurerm"
          version = "~> 3.0"
        }
      }
      required_version = ">= 1.9.0"
    }
    
    provider "azurerm" {
      features {}
      
      # Subscription ID would be configured here
      # subscription_id = "${try(local.cfg.subscription_id, "")}"
    }
  EOF
}

# TODO: Implement Azure remote state backend
# For now, this is commented out as a placeholder
#
# remote_state {
#   backend = "azurerm"
#   config = {
#     resource_group_name  = "honeyhive-terraform-state"
#     storage_account_name = "honeyhivetfstate${local.sregion}"
#     container_name       = "tfstate"
#     key                  = "${local.org}/${local.env}/${local.sregion}/${local.deployment}/${local.layer}/${local.service}/tfstate.json"
#   }
# }

# Terraform version constraints
terraform_version_constraint = ">= 1.9.0"
terragrunt_version_constraint = ">= 0.66.0"

# Placeholder for Azure-specific configuration
terraform {
  before_hook "azure_stub_warning" {
    commands = ["plan", "apply", "destroy"]
    execute  = ["bash", "-c", "echo '⚠️  Warning: Azure overlay is a stub implementation. Full Azure support coming soon.'"]
  }
}
