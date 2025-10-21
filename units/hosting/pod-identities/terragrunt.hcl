# Pod Identity Associations Unit - IAM roles for Kubernetes service accounts

include "root" {
  path   = find_in_parent_folders("includes/stack-config.hcl")
  expose = true
}

# Dependencies handled at stack level via depends_on in terragrunt.stack.hcl
# No unit-level dependencies needed - stack execution order is enforced by stack

terraform {
  source = "git::https://github.com/honeyhiveai/honeyhive-terraform.git//hosting/aws/pod_identities?ref=${include.root.locals.terraform_ref}"
}

inputs = {
  # Core variables
  org        = include.root.locals.org
  env        = include.root.locals.env
  region     = include.root.locals.region
  sregion    = include.root.locals.sregion
  deployment = include.root.locals.deployment
  
  layer   = "hosting"
  service = "pod_identities"
}

