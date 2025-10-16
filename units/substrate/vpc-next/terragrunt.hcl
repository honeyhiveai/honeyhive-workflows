# VPC Unit - Foundation networking layer
# This is the first resource deployed in the substrate stack

# Include shared configurations
include "tenant_config" {
  path   = find_in_parent_folders("includes/tenant-config.hcl")
  expose = true
}

include "deployment_types" {
  path   = find_in_parent_folders("includes/deployment-types.hcl")
  expose = true
}

include "remote_state" {
  path = find_in_parent_folders("includes/remote-state.hcl")
}

include "aws_provider" {
  path = find_in_parent_folders("includes/aws-provider.hcl")
}

# Skip if VPC component is disabled for this deployment type
skip = !try(include.deployment_types.locals.deployment_components.substrate.vpc, true)

# Terraform module source
terraform {
  source = "git::https://github.com/honeyhiveai/honeyhive-terraform.git//substrate/aws/vpc?ref=${include.tenant_config.locals.terraform_ref}"
}

# Module inputs - adjusted based on deployment type
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
  
  # NAT gateway configuration varies by deployment type
  nat_gateway_count = include.deployment_types.locals.current_deployment_type == "edge" ? 0 : 
                     include.deployment_types.locals.current_deployment_type == "data_plane" ? 1 :
                     try(include.tenant_config.locals.cfg.nat_gateway_count, 1)
  
  # VPC endpoints - more for control plane, fewer for data plane
  enable_vpc_endpoints = include.deployment_types.locals.deployment_features.network_isolation ? true :
                        include.deployment_types.locals.current_deployment_type == "control_plane" ? true :
                        try(include.tenant_config.locals.cfg.enable_vpc_endpoints, false)
  
  # Subnet configuration - sizes vary by deployment type
  public_subnet_cidrs = try(
    include.tenant_config.locals.cfg.public_subnet_cidrs,
    include.deployment_types.locals.current_deployment_type == "edge" ? 
      ["10.0.1.0/28", "10.0.2.0/28"] :  # Tiny for edge
      ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]  # Standard
  )
  
  private_subnet_cidrs = try(
    include.tenant_config.locals.cfg.private_subnet_cidrs,
    include.deployment_types.locals.current_deployment_type == "data_plane" ?
      ["10.0.10.0/23", "10.0.12.0/23", "10.0.14.0/23"] :  # Larger for compute
    include.deployment_types.locals.current_deployment_type == "edge" ?
      ["10.0.10.0/27", "10.0.10.32/27"] :  # Tiny for edge
      ["10.0.10.0/24", "10.0.11.0/24", "10.0.12.0/24"]  # Standard
  )
  
  # Tags including deployment type
  tags = merge(
    include.tenant_config.locals.common_tags,
    {
      DeploymentType = include.deployment_types.locals.current_deployment_type
      Component      = "substrate-vpc"
    }
  )
}