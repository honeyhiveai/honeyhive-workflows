# Application ECR Repositories Unit - Container Registry for Services

include "root" {
  path   = find_in_parent_folders("includes/stack-config.hcl")
  expose = true
}

# Note: Cross-stack dependencies for sequencing are handled by full.stack.yaml
# When running standalone application stack, these dependencies are not needed

terraform {
  source = "git::https://github.com/honeyhiveai/honeyhive-terraform.git//application/aws/ecr?ref=${include.root.locals.terraform_ref}"
}

inputs = {
  # Core variables
  org        = include.root.locals.org
  env        = include.root.locals.env
  region     = include.root.locals.region
  sregion    = include.root.locals.sregion
  deployment = include.root.locals.deployment

  # Deployment type determines which repos to create
  deployment_type = try(include.root.locals.cfg.deployment_type, "full_stack")

  # Tags from parent configuration
  tags = {
    Organization = include.root.locals.org
    Environment  = include.root.locals.env
    Region       = include.root.locals.region
    Deployment   = include.root.locals.deployment
    ManagedBy    = "Terraform"
    Repository   = "https://github.com/honeyhiveai/honeyhive-terraform.git"
    Stack        = "terragrunt-stacks"
    Layer        = "application"
    Service      = "ecr"
  }

  # ECR Configuration
  enable_cross_account_access = false  # Set to true if cross-account access needed
  cross_account_principals      = []     # List of account ARNs for cross-account access
}

