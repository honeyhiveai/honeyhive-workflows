# Full Stack - Complete HoneyHive platform deployment
# This stack orchestrates all layers: substrate, hosting, and application

# Substrate Layer
unit "vpc" {
  source = "../../../units/substrate/vpc-next"
  path   = "substrate/vpc"
}

unit "dns" {
  source = "../../../units/substrate/dns-next"
  path   = "substrate/dns"
  
}

unit "twingate" {
  source = "../../../units/substrate/twingate-next"
  path   = "substrate/twingate"
  
}

# Hosting Layer
unit "cluster" {
  source = "../../../units/hosting/cluster-next"
  path   = "hosting/cluster"
  
}

unit "karpenter" {
  source = "../../../units/hosting/karpenter-next"
  path   = "hosting/karpenter"
  
}

unit "addons" {
  source = "../../../units/hosting/addons-next"
  path   = "hosting/addons"
  
}

unit "pod_identities" {
  source = "../../../units/hosting/pod_identities-next"
  path   = "hosting/pod_identities"
  
}

# Application Layer
unit "database" {
  source = "../../../units/application/database-next"
  path   = "application/database"
  
}

unit "s3" {
  source = "../../../units/application/s3-next"
  path   = "application/s3"
  
}

