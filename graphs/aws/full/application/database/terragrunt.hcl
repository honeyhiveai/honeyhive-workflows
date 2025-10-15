# RDS Database - Application data persistence
# Depends on: VPC (for networking), Cluster (for connectivity)

include "root" {
  path = "${get_repo_root()}/overlays/aws/root.hcl"
}

locals {
  cfg = yamldecode(file(get_env("TENANT_CONFIG_PATH")))
}
  
