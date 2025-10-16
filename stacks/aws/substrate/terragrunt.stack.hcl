# Substrate Stack - Foundation networking and security layer
# Dependencies are handled by dependency blocks in each unit's terragrunt.hcl

unit "vpc" {
  source = "../../../units/substrate/vpc-next"
  path   = "vpc"
}

unit "dns" {
  source = "../../../units/substrate/dns-next"
  path   = "dns"
}

unit "twingate" {
  source = "../../../units/substrate/twingate-next"
  path   = "twingate"
}
