# Pod Identity Associations Unit - IAM roles for Kubernetes service accounts

include "root" {
  path   = find_in_parent_folders("includes/stack-config.hcl")
  expose = true
}

dependency "cluster" {
  config_path = "../cluster"
  
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan"]
  mock_outputs = {
    cluster_name = "mock-cluster"
  }
}

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

