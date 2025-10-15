# Twingate VPN - Optional secure access
# Depends on: VPC (for networking)
# Optional: Deployed based on deployment_type and features.twingate

include "root" {
  path = "${get_repo_root()}/overlays/aws/root.hcl"
}

locals {
  cfg = yamldecode(file(get_env("TENANT_CONFIG_PATH")))
}

# Skip if twingate feature is disabled
skip = !try(local.cfg.features.twingate, false)

# Remote state configuration for this service
remote_state {
  backend = "s3"
  config = {
    bucket         = try(local.cfg.state_bucket, "honeyhive-federated-${local.cfg.sregion}-state")
    key            = "${local.cfg.org}/${local.cfg.env}/${local.cfg.sregion}/${local.cfg.deployment}/substrate/twingate/tfstate.json"
    region         = local.cfg.region
    encrypt        = true
    dynamodb_table = "honeyhive-orchestration-terraform-state-lock"
  }
  
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite"
  }
}

  
