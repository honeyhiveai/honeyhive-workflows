# Full Stack - Complete HoneyHive platform deployment
# This stack orchestrates all layers: substrate, hosting, and application

# Substrate Layer
unit "vpc" {
  source = "../../../units/substrate/vpc"
  path   = "substrate/vpc"
}

unit "dns" {
  source = "../../../units/substrate/dns"
  path   = "substrate/dns"

}

unit "twingate" {
  source = "../../../units/substrate/twingate"
  path   = "substrate/twingate"

}

# Hosting Layer
unit "cluster" {
  source = "../../../units/hosting/cluster"
  path   = "hosting/cluster"

}

unit "karpenter" {
  source = "../../../units/hosting/karpenter"
  path   = "hosting/karpenter"

}

unit "addons" {
  source = "../../../units/hosting/addons"
  path   = "hosting/addons"

}

unit "pod_identities" {
  source = "../../../units/hosting/pod-identities"
  path   = "hosting/pod-identities"

}

# Application Layer
unit "database" {
  source = "../../../units/application/database"
  path   = "application/database"

}

unit "s3" {
  source = "../../../units/application/s3"
  path   = "application/s3"

}

