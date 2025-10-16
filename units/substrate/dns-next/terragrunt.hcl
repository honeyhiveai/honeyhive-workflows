# DNS Unit - Private hosted zone for internal service discovery
# Depends on VPC for zone association

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

# Explicit dependency on VPC
dependency "vpc" {
  config_path = "../vpc-next"
  
  # Mock outputs for plan-time validation
  mock_outputs = {
    vpc_id = "vpc-mock123456"
  }
  
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan"]
  mock_outputs_merge_strategy_with_state  = "shallow"
}

# Terraform module source
terraform {
  source = "git::https://github.com/honeyhiveai/honeyhive-terraform.git//substrate/aws/dns?ref=${include.tenant_config.locals.terraform_ref}"
}

# Module inputs
inputs = {
  # Core identifiers
  org        = include.tenant_config.locals.org
  env        = include.tenant_config.locals.env
  region     = include.tenant_config.locals.region
  sregion    = include.tenant_config.locals.sregion
  deployment = include.tenant_config.locals.deployment
  
  # DNS configuration from tenant config
  domain_name   = include.tenant_config.locals.cfg.domain_name
  dns_zone_name = include.tenant_config.locals.cfg.dns_zone_name
  
  # VPC dependency
  vpc_id = dependency.vpc.outputs.vpc_id
  
  # Tags
  tags = include.tenant_config.locals.common_tags
}
