# Application Database Unit - PostgreSQL RDS Instance

include "root" {
  path   = find_in_parent_folders("includes/stack-config.hcl")
  expose = true
}

# Dependencies for execution order
# Note: Cross-stack dependencies (substrate/vpc) are handled via remote state
# No local path dependency needed - Terragrunt will read from remote state

dependency "vpc" {
  config_path = "../../substrate/vpc"

  mock_outputs = {
    vpc_id             = "vpc-00000000000000000"
    private_subnet_ids = ["subnet-00000000000000001", "subnet-00000000000000002", "subnet-00000000000000003"]
    vpc_cidr_block     = "10.0.0.0/16"
  }

  # Skip outputs if running application stack standalone (substrate may not exist locally)
  # Terragrunt will fall back to remote state if config_path doesn't exist
  skip_outputs = false
  skip = false
}

terraform {
  source = "git::https://github.com/honeyhiveai/honeyhive-terraform.git//application/aws/database?ref=${include.root.locals.terraform_ref}"
}

inputs = {
  # Core variables
  org        = include.root.locals.org
  env        = include.root.locals.env
  region     = include.root.locals.region
  sregion    = include.root.locals.sregion
  deployment = include.root.locals.deployment
  account_id = include.root.locals.account_id

  # Network dependencies
  vpc_id             = dependency.vpc.outputs.vpc_id
  private_subnet_ids = dependency.vpc.outputs.private_subnet_ids

  # Database configuration
  database_name      = "hh-${include.root.locals.deployment}"
  engine_version     = "17"
  instance_class     = "db.r6g.xlarge"
  allocated_storage  = 100
  storage_type       = "gp3"
  storage_encrypted   = true
  multi_az           = true
  backup_retention_period = 7
  backup_window      = "03:00-04:00"
  maintenance_window = "sun:04:00-sun:05:00"
  deletion_protection = true
  performance_insights_enabled = true
  monitoring_interval = 60

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
    Service      = "database"
  }
}

