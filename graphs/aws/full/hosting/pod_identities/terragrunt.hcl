# Pod Identities - IAM roles for Kubernetes pods
# Depends on: EKS Cluster (for OIDC provider)

include "root" {
  path = "${get_repo_root()}/overlays/aws/root.hcl"
}

locals {
  cfg = yamldecode(file(get_env("TENANT_CONFIG_PATH")))
}
  
