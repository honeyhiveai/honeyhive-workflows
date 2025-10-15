# Karpenter - Kubernetes node autoscaling
# Depends on: EKS Cluster (for OIDC provider, cluster name)
# Optional: Deployed based on deployment_type and features.karpenter

include "root" {
  path = "${get_repo_root()}/overlays/aws/root.hcl"
}

locals {
  cfg = yamldecode(file(get_env("TENANT_CONFIG_PATH")))
}
  
