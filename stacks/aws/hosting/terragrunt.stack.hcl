# Hosting Stack - Kubernetes platform layer

unit "cluster" {
  source = "../../../units/hosting/cluster"
  path   = "cluster"
}

unit "karpenter" {
  source = "../../../units/hosting/karpenter"
  path   = "karpenter"
  
  depends_on = ["cluster"]
}

unit "addons" {
  source = "../../../units/hosting/addons"
  path   = "addons"
  
  depends_on = ["cluster", "karpenter"]
}

unit "pod_identities" {
  source = "../../../units/hosting/pod-identities"
  path   = "pod-identities"
  
  depends_on = ["cluster"]
}
