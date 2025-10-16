# Substrate Stack - Foundation networking and security layer
# This stack includes VPC, DNS, and Twingate (conditionally)

unit "vpc" {
  source = "../../../units/substrate/vpc-next"
  path   = "vpc"
}

unit "dns" {
  source = "../../../units/substrate/dns-next"
  path   = "dns"
  
  # DNS depends on VPC
  dependencies = [unit.vpc]
}

unit "twingate" {
  source = "../../../units/substrate/twingate-next"
  path   = "twingate"
  
  # Twingate depends on VPC
  dependencies = [unit.vpc]
}

