# Twingate Unit - Zero-trust VPN for secure access
# Depends on VPC for network connectivity

# Include shared configurations
include "tenant_config" {
  path   = find_in_parent_folders("includes/tenant-config.hcl")
  expose = true
}

include "remote_state" {
  path = find_in_parent_folders("includes/remote-state.hcl")
}

include "aws_provider" {
  path = find_in_parent_folders("includes/aws-provider.hcl")
}

# Conditional skip based on feature flag
skip = !try(include.tenant_config.locals.features.twingate, false)

# Explicit dependency on VPC
dependency "vpc" {
  config_path = "../vpc-next"
  
  # Mock outputs for plan-time validation
  mock_outputs = {
    vpc_id             = "vpc-mock123456"
    private_subnet_ids = ["subnet-mock1", "subnet-mock2"]
  }
  
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan"]
  mock_outputs_merge_strategy_with_state  = "shallow"
  
  # Skip dependency if this unit is being skipped
  skip_outputs = try(!include.tenant_config.locals.features.twingate, false)
}

# Terraform module source
terraform {
  source = "git::https://github.com/honeyhiveai/honeyhive-terraform.git//substrate/aws/twingate?ref=${include.tenant_config.locals.terraform_ref}"
}

# Module inputs
inputs = {
  # Core identifiers
  org        = include.tenant_config.locals.org
  env        = include.tenant_config.locals.env
  region     = include.tenant_config.locals.region
  sregion    = include.tenant_config.locals.sregion
  deployment = include.tenant_config.locals.deployment
  
  # Twingate configuration
  twingate_network_name = try(
    include.tenant_config.locals.cfg.twingate_network_name,
    "${include.tenant_config.locals.name_prefix}-network"
  )
  
  # VPC dependencies
  vpc_id             = dependency.vpc.outputs.vpc_id
  private_subnet_ids = dependency.vpc.outputs.private_subnet_ids
  
  # ECS configuration for connector containers
  connector_count      = try(include.tenant_config.locals.cfg.twingate_connector_count, 2)
  connector_cpu        = try(include.tenant_config.locals.cfg.twingate_connector_cpu, 256)
  connector_memory     = try(include.tenant_config.locals.cfg.twingate_connector_memory, 512)
  
  # Tags
  tags = include.tenant_config.locals.common_tags
}
