# Hosting Stack - Kubernetes platform layer

unit "cluster" {
  source = "../../../units/hosting/cluster"
  path   = "cluster"
}

unit "karpenter" {
  source = "../../../units/hosting/karpenter"
  path   = "karpenter"
}

unit "addons" {
  source = "../../../units/hosting/addons"
  path   = "addons"
}

unit "pod_identities" {
  source = "../../../units/hosting/pod-identities"
  path   = "pod-identities"
}
