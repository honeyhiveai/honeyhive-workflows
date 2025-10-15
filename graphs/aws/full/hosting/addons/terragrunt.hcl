# EKS Addons - Core cluster components (CoreDNS, metrics-server, ALB controller, ESO, etc.)
# Depends on: Cluster, Karpenter (Karpenter must provision nodes first)

include "root" {
  path = "${get_repo_root()}/overlays/aws/root.hcl"
}

locals {
  cfg = yamldecode(file(get_env("TENANT_CONFIG_PATH")))
}
  
