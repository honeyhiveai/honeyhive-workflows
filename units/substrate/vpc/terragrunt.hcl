# VPC Unit - Foundation network infrastructure

include "root" {
  path   = find_in_parent_folders("includes/stack-config.hcl")
  expose = true
}

terraform {
  source = "git::https://github.com/honeyhiveai/honeyhive-terraform.git//substrate/aws/vpc?ref=${include.root.locals.terraform_ref}"
}

# Compute cluster name for Karpenter discovery tags
locals {
  cluster_name = "${include.root.locals.org}-${include.root.locals.env}-${include.root.locals.sregion}-${include.root.locals.deployment}"
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

  # Karpenter discovery tags for private subnets
  private_subnet_extra_tags = {
    "karpenter.sh/discovery" = local.cluster_name
  }

  # VPC Gateway Endpoints (no charge, route through VPC)
  gateway_endpoints = {
    s3 = {
      service         = "s3"
      route_table_ids = [] # Empty list means apply to all route tables
    }
  }

  # VPC Interface Endpoints (private connectivity to AWS services)
  interface_endpoints = {
    secretsmanager = {
      service             = "secretsmanager"
      private_dns_enabled = true
    }
    sqs = {
      service             = "sqs"
      private_dns_enabled = true
    }
    ecr_dkr = {
      service             = "ecr.dkr"
      private_dns_enabled = true
    }
    sts = {
      service             = "sts"
      private_dns_enabled = true
    }
    logs = {
      service             = "logs"
      private_dns_enabled = true
    }
    ssm = {
      service             = "ssm"
      private_dns_enabled = true
    }
    eks = {
      service             = "eks"
      private_dns_enabled = true
    }
  }

  endpoint_tags = {}
}
