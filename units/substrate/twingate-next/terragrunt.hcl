# Twingate Unit - VPN access to private infrastructure

include "root" {
  path   = find_in_parent_folders("includes/stack-config.hcl")
  expose = true
}

dependency "vpc" {
  config_path = "../vpc-next"
  
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan"]
  mock_outputs = {
    vpc_id              = "mock-vpc-id"
    private_subnet_ids  = ["mock-subnet-1", "mock-subnet-2"]
    vpc_cidr_block      = "10.0.0.0/16"
  }
}

terraform {
  source = "git::https://github.com/honeyhiveai/honeyhive-terraform.git//substrate/aws/twingate?ref=${include.root.locals.terraform_ref}"
}

# Generate Twingate provider configuration
generate "twingate_provider" {
  path      = "twingate_provider.tf"
  if_exists = "overwrite_terragrunt"
  contents = <<EOF
provider "twingate" {
  api_token = "${get_env("TWINGATE_API_TOKEN")}"
  network   = "${include.root.locals.cfg.twingate_network}"
}
EOF
}

inputs = {
  # Core variables
  org        = include.root.locals.org
  env        = include.root.locals.env
  region     = include.root.locals.region
  sregion    = include.root.locals.sregion
  deployment = include.root.locals.deployment
  account_id = include.root.locals.account_id
  
  layer   = "substrate"
  service = "twingate"
  
  # VPC dependencies
  vpc_id              = dependency.vpc.outputs.vpc_id
  private_subnet_ids  = dependency.vpc.outputs.private_subnet_ids
  vpc_cidr            = include.root.locals.cfg.vpc_cidr
  
  # DNS configuration
  domain_name    = include.root.locals.cfg.domain_name
  dns_zone_name  = include.root.locals.cfg.dns_zone_name
  
  # Twingate configuration
  twingate_network     = include.root.locals.cfg.twingate_network
  twingate_dns_server  = try(include.root.locals.cfg.twingate_dns_server, cidrhost(include.root.locals.cfg.vpc_cidr, 2)) # VPC DNS is .2
  twingate_group_id    = try(include.root.locals.cfg.twingate_group_id, get_env("TWINGATE_GROUP_ID", ""))
  twingate_api_token   = get_env("TWINGATE_API_TOKEN")
}
