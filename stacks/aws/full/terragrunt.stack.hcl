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
  
  dependencies = [unit.vpc]
}

unit "twingate" {
  source = "../../../units/substrate/twingate-next"
  path   = "substrate/twingate"
  
  dependencies = [unit.vpc]
}

# Hosting Layer
unit "cluster" {
  source = "../../../units/hosting/cluster-next"
  path   = "hosting/cluster"
  
  dependencies = [unit.vpc]
}

unit "karpenter" {
  source = "../../../units/hosting/karpenter-next"
  path   = "hosting/karpenter"
  
  dependencies = [unit.cluster]
}

unit "addons" {
  source = "../../../units/hosting/addons-next"
  path   = "hosting/addons"
  
  dependencies = [unit.cluster, unit.karpenter]
}

unit "pod_identities" {
  source = "../../../units/hosting/pod_identities-next"
  path   = "hosting/pod_identities"
  
  dependencies = [unit.cluster]
}

# Application Layer
unit "database" {
  source = "../../../units/application/database-next"
  path   = "application/database"
  
  dependencies = [unit.vpc, unit.cluster]
}

unit "s3" {
  source = "../../../units/application/s3-next"
  path   = "application/s3"
  
  dependencies = [unit.cluster]
}

