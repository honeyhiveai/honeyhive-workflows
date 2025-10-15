# Twingate VPN - Optional secure access
# Depends on: VPC (for networking)
# Optional: Deployed based on deployment_type and features.twingate

include "root" {
  path = "${get_repo_root()}/overlays/aws/root.hcl"
}

locals {
  cfg = yamldecode(file(get_env("TENANT_CONFIG_PATH")))
}
  
