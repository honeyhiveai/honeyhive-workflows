# Application Database Unit - PostgreSQL RDS Instance

include "root" {
  path   = find_in_parent_folders("includes/stack-config.hcl")
  expose = true
}

# Cross-stack dependency on substrate/vpc
# NOTE: Dependency block removed - Terragrunt Stacks cannot process cross-stack
# dependencies when paths don't exist locally. Module should read from remote state.
# TODO: Update application/aws/database module to read VPC outputs from remote state

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

  # Network dependencies - TODO: Module should read from remote state
  # For now, using mock values - will fail during apply until module is updated
  vpc_id             = "vpc-00000000000000000"  # TODO: Read from remote state
  private_subnet_ids = ["subnet-00000000000000001", "subnet-00000000000000002", "subnet-00000000000000003"]  # TODO: Read from remote state

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

