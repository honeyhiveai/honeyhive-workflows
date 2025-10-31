# Application IAM Unit - Control Plane Service Roles and Pod Identity

include "root" {
  path   = find_in_parent_folders("includes/stack-config.hcl")
  expose = true
}

# Dependencies for execution order
dependencies {
  paths = [
    "../s3"  # Same-stack dependency - will work
    # Note: hosting/cluster is cross-stack - handled via remote state
  ]
}

dependency "s3" {
  config_path = "../s3"

  mock_outputs = {
    bucket_name = "${include.root.locals.org}-${include.root.locals.env}-${include.root.locals.sregion}-${include.root.locals.deployment}-store"
  }

  skip_outputs = false
}

dependency "cluster" {
  config_path = "../../hosting/cluster"

  mock_outputs = {
    cluster_name = "${include.root.locals.org}-${include.root.locals.env}-${include.root.locals.sregion}-${include.root.locals.deployment}"
    cluster_endpoint = "https://${include.root.locals.org}-${include.root.locals.env}-${include.root.locals.sregion}-${include.root.locals.deployment}.gr7.${include.root.locals.region}.eks.amazonaws.com"
    cluster_certificate_authority_data = "LS0tLS1CRUdJTi..."
  }

  # Skip outputs when running application stack standalone
  # Terraform module should read from remote state instead
  skip_outputs = true
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan"]
}

terraform {
  source = "git::https://github.com/honeyhiveai/honeyhive-terraform.git//application/aws/iam?ref=${include.root.locals.terraform_ref}"
}

inputs = {
  # Core variables
  org        = include.root.locals.org
  env        = include.root.locals.env
  region     = include.root.locals.region
  sregion    = include.root.locals.sregion
  deployment = include.root.locals.deployment
  account_id = include.root.locals.account_id

  # Dependencies
  cluster_name       = dependency.cluster.outputs.cluster_name
  store_bucket_name  = dependency.s3.outputs.bucket_name
  cp_namespace       = "control-plane"

  # Tags from parent configuration
  tags = {
    Organization = include.root.locals.org
    Environment  = include.root.locals.env
    Region       = include.root.locals.region
    Deployment   = include.root.locals.deployment
    ManagedBy    = "Terraform"
    Repository   = "https://github.com/honeyhiveai/deployments.git"
    Stack        = "terragrunt-stacks"
    Layer        = "application"
    Service      = "iam"
  }
}

