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
  
  # VPC CIDR - required
  vpc_cidr = include.tenant_config.locals.cfg.vpc_cidr
  
  # Subnet configuration - VPC module handles automatic creation
  # Number of AZs to use (module automatically selects first N available)
  subnet_count = try(
    include.tenant_config.locals.cfg.subnet_count,
    include.deployment_types.locals.current_deployment_type == "edge" ? 1 :
    include.deployment_types.locals.current_deployment_type == "control_plane" ? 2 :
    3  # Default to 3 AZs for most deployments
  )
  
  # NAT strategy based on deployment type
  subnet_nat_strategy = try(
    include.tenant_config.locals.cfg.subnet_nat_strategy,
    include.deployment_types.locals.current_deployment_type == "edge" ? "none" :
    include.deployment_types.locals.current_deployment_type == "data_plane" ? "single" :
    include.deployment_types.locals.current_deployment_type == "control_plane" ? "per_az" :
    include.deployment_types.locals.current_deployment_type == "federated_byoc" ? "per_az" :
    "single"  # Default to single NAT for cost optimization
  )
  
  # Subnet sizing - controls how module splits the VPC CIDR
  # These are "newbits" added to create subnets from VPC CIDR
  subnet_public_newbits = try(
    include.tenant_config.locals.cfg.subnet_public_newbits,
    include.deployment_types.locals.current_deployment_type == "edge" ? 12 :  # Tiny /28 from /16
    8  # Default /24 from /16 VPC
  )
  
  subnet_private_newbits = try(
    include.tenant_config.locals.cfg.subnet_private_newbits,
    include.deployment_types.locals.current_deployment_type == "data_plane" ? 2 :  # Large /18 for compute
    include.deployment_types.locals.current_deployment_type == "edge" ? 12 :  # Tiny /28 for edge
    4  # Default /20 from /16 VPC
  )
  
  # Optional: Explicit AZ names (module auto-selects if not provided)
  subnet_azs = try(include.tenant_config.locals.cfg.subnet_azs, null)
  
  # Optional: Override automatic subnet CIDR calculation
  subnet_public_cidrs = try(include.tenant_config.locals.cfg.subnet_public_cidrs, null)
  subnet_private_cidrs = try(include.tenant_config.locals.cfg.subnet_private_cidrs, null)
  
  # VPC endpoints - varies by deployment type
  gateway_endpoints = try(
    include.tenant_config.locals.cfg.gateway_endpoints,
    include.deployment_types.locals.current_deployment_type == "control_plane" ? {
      s3 = {
        service = "s3"
        route_table_ids = []  # Module will auto-attach to all route tables
      }
    } : {}
  )
  
  interface_endpoints = try(
    include.tenant_config.locals.cfg.interface_endpoints,
    include.deployment_types.locals.deployment_features.network_isolation ? {
      ecr_dkr = { service = "ecr.dkr", private_dns_enabled = true }
      ecr_api = { service = "ecr.api", private_dns_enabled = true }
      logs = { service = "logs", private_dns_enabled = true }
      ssm = { service = "ssm", private_dns_enabled = true }
      secretsmanager = { service = "secretsmanager", private_dns_enabled = true }
      sts = { service = "sts", private_dns_enabled = true }
    } :
    include.deployment_types.locals.current_deployment_type == "control_plane" ? {
      ecr_dkr = { service = "ecr.dkr", private_dns_enabled = true }
      logs = { service = "logs", private_dns_enabled = true }
      ssm = { service = "ssm", private_dns_enabled = true }
    } : {}
  )
  
  # DHCP options
  enable_dhcp_options = try(include.tenant_config.locals.cfg.enable_dhcp_options, true)
  dhcp_options = try(
    include.tenant_config.locals.cfg.dhcp_options,
    { domain_name_servers = ["AmazonProvidedDNS"] }
  )
  
  # Tags including deployment type
  tags = merge(
    include.tenant_config.locals.common_tags,
    {
      DeploymentType = include.deployment_types.locals.current_deployment_type
      Component      = "substrate-vpc"
    }
  )
  
  # Subnet tags for workload integration (e.g., Kubernetes)
  subnet_tags = try(
    include.tenant_config.locals.cfg.subnet_tags,
    {}
  )
  
  public_subnet_extra_tags = try(
    include.tenant_config.locals.cfg.public_subnet_extra_tags,
    include.deployment_types.locals.current_deployment_type != "edge" ? {
      "kubernetes.io/role/elb" = "1"
    } : {}
  )
  
  private_subnet_extra_tags = try(
    include.tenant_config.locals.cfg.private_subnet_extra_tags,
    include.deployment_types.locals.current_deployment_type != "edge" ? {
      "kubernetes.io/role/internal-elb" = "1"
    } : {}
  )
}