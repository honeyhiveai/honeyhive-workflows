# Substrate Stack - Foundation networking and security layer
# Path names must match what dependency blocks expect

unit "vpc" {
  source = "../../../units/substrate/vpc"
  path   = "vpc"
}

unit "dns" {
  source = "../../../units/substrate/dns"
  path   = "dns"
}

unit "twingate" {
  source = "../../../units/substrate/twingate"
  path   = "twingate"
}
