# VPC Unit - Foundation network infrastructure

include "root" {
  path   = find_in_parent_folders("includes/stack-config.hcl")
  expose = true
}

terraform {
  source = "git::https://github.com/honeyhiveai/honeyhive-terraform.git//substrate/aws/vpc?ref=${include.root.locals.terraform_ref}"
}

inputs = {
  # Core variables from config
  org        = include.root.locals.org
  env        = include.root.locals.env
  region     = include.root.locals.region
  sregion    = include.root.locals.sregion
  deployment = include.root.locals.deployment
  account_id = include.root.locals.account_id

  layer   = "substrate"
  service = "vpc"

  # VPC configuration
  vpc_cidr               = include.root.locals.cfg.vpc_cidr
  subnet_count           = try(include.root.locals.cfg.network_config.availability_zones, 3)
  subnet_nat_strategy    = try(include.root.locals.cfg.network_config.nat_strategy, "single")
  subnet_public_newbits  = try(include.root.locals.cfg.network_config.public_subnet_bits, 7)
  subnet_private_newbits = try(include.root.locals.cfg.network_config.private_subnet_bits, 3)

  # DHCP Options - disable to avoid null value errors
  enable_dhcp_options = false
  dhcp_options        = {}

  # VPC Endpoints - will be populated after VPC creation
  gateway_endpoints   = {}
  interface_endpoints = {}
  endpoint_tags       = {}
}
