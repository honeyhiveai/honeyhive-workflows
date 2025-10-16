# VPC Unit - Foundation network infrastructure

include "root" {
  path   = find_in_parent_folders("includes/stack-config.hcl")
  expose = true
}

terraform {
  source = "git::https://github.com/honeyhiveai/honeyhive-terraform.git//substrate/aws/vpc?ref=${include.root.locals.terraform_ref}"
}

inputs = merge(
  include.root.locals.cfg,
  {
    layer   = "substrate"
    service = "vpc"
    
    # VPC configuration
    vpc_cidr               = include.root.locals.cfg.vpc_cidr
    subnet_count           = try(include.root.locals.cfg.network_config.availability_zones, 3)
    subnet_nat_strategy    = try(include.root.locals.cfg.network_config.nat_strategy, "single")
    subnet_public_newbits  = try(include.root.locals.cfg.network_config.public_subnet_bits, 7)
    subnet_private_newbits = try(include.root.locals.cfg.network_config.private_subnet_bits, 3)
    
    # VPC Endpoints
    gateway_endpoints = {
      s3 = { service = "s3" }
    }
    interface_endpoints = {
      logs           = { service = "logs", private_dns_enabled = true }
      ecr_api        = { service = "ecr.api", private_dns_enabled = true }
      ecr_dkr        = { service = "ecr.dkr", private_dns_enabled = true }
      ssm            = { service = "ssm", private_dns_enabled = true }
      secretsmanager = { service = "secretsmanager", private_dns_enabled = true }
      sqs            = { service = "sqs", private_dns_enabled = true }
      sts            = { service = "sts", private_dns_enabled = true }
    }
  }
)
