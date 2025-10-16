# DNS Unit - Private DNS zone for internal services

include "root" {
  path   = find_in_parent_folders("includes/stack-config.hcl")
  expose = true
}

dependency "vpc" {
  config_path = "../vpc-next"
  
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan"]
  mock_outputs = {
    vpc_id         = "mock-vpc-id"
    vpc_cidr_block = "10.0.0.0/16"
  }
}

terraform {
  source = "git::https://github.com/honeyhiveai/honeyhive-terraform.git//substrate/aws/dns?ref=${include.root.locals.terraform_ref}"
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
  service = "dns"
  
  vpc_id        = dependency.vpc.outputs.vpc_id
  dns_zone_name = try(include.root.locals.cfg.dns_zone_name, "${include.root.locals.deployment}.${include.root.locals.sregion}.${include.root.locals.env}.${include.root.locals.cfg.shortname}.${include.root.locals.cfg.domain_name}")
}
