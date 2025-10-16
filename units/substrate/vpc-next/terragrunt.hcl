# VPC Unit - Foundation networking layer
# This is the first resource deployed in the substrate stack

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

# Terraform module source
terraform {
  source = "git::https://github.com/honeyhiveai/honeyhive-terraform.git//substrate/aws/vpc?ref=${include.tenant_config.locals.terraform_ref}"
}

# Module inputs
inputs = {
  # Core identifiers
  org        = include.tenant_config.locals.org
  env        = include.tenant_config.locals.env
  region     = include.tenant_config.locals.region
  sregion    = include.tenant_config.locals.sregion
  deployment = include.tenant_config.locals.deployment
  
  # VPC configuration from tenant config
  vpc_cidr             = include.tenant_config.locals.cfg.vpc_cidr
  availability_zones   = include.tenant_config.locals.cfg.availability_zones
  nat_gateway_count    = try(include.tenant_config.locals.cfg.nat_gateway_count, 1)
  enable_vpc_endpoints = try(include.tenant_config.locals.cfg.enable_vpc_endpoints, true)
  
  # Subnet configuration
  public_subnet_cidrs  = try(include.tenant_config.locals.cfg.public_subnet_cidrs, [])
  private_subnet_cidrs = try(include.tenant_config.locals.cfg.private_subnet_cidrs, [])
  
  # Tags
  tags = include.tenant_config.locals.common_tags
}
