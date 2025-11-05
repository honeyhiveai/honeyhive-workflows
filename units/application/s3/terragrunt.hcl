# Application S3 Storage Unit - Control Plane Data Storage

include "root" {
  path   = find_in_parent_folders("includes/stack-config.hcl")
  expose = true
}

# Dependencies to ensure hosting layer completes before application starts
dependencies {
  paths = [
    "../../hosting/addons"  # Ensure hosting layer completes before application starts
  ]
}

terraform {
  source = "git::https://github.com/honeyhiveai/honeyhive-terraform.git//application/aws/s3?ref=${include.root.locals.terraform_ref}"
}

inputs = {
  # Core variables
  org        = include.root.locals.org
  env        = include.root.locals.env
  region     = include.root.locals.region
  sregion    = include.root.locals.sregion
  deployment = include.root.locals.deployment

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
    Service      = "s3"
  }

  # S3 Configuration
  enable_access_logging = false
}

