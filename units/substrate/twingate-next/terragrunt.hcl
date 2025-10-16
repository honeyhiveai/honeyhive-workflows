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

inputs = merge(
  include.root.locals.cfg,
  {
    layer   = "substrate"
    service = "twingate"
    
    vpc_id     = dependency.vpc.outputs.vpc_id
    subnet_ids = dependency.vpc.outputs.private_subnet_ids
  }
)
