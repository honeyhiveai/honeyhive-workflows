# Hosting Stack - Kubernetes platform layer
# This stack includes EKS cluster, Karpenter, addons, and pod identities

unit "cluster" {
  source = "../../../units/hosting/cluster-next"
  path   = "cluster"
}

unit "karpenter" {
  source = "../../../units/hosting/karpenter-next"
  path   = "karpenter"
  
}

unit "addons" {
  source = "../../../units/hosting/addons-next"
  path   = "addons"
  
}

unit "pod_identities" {
  source = "../../../units/hosting/pod_identities-next"
  path   = "pod_identities"
  
}

