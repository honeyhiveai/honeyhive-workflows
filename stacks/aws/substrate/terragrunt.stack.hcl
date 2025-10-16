# Substrate Stack - Foundation networking and security layer
# Path names must match what dependency blocks expect

unit "vpc" {
  source = "../../../units/substrate/vpc-next"
  path   = "vpc-next"
}

unit "dns" {
  source = "../../../units/substrate/dns-next"
  path   = "dns-next"
}

unit "twingate" {
  source = "../../../units/substrate/twingate-next"
  path   = "twingate-next"
}
