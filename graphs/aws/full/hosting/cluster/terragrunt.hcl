# EKS Cluster - Kubernetes control plane and managed node groups
# Depends on: VPC (for networking)

include "root" {
  path = "${get_repo_root()}/overlays/aws/root.hcl"
}

locals {
  cfg = yamldecode(file(get_env("TENANT_CONFIG_PATH")))
}
  
