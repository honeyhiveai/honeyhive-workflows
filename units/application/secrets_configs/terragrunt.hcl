# Application Secrets and Configs Unit - Aggregates outputs from modules and user config
# Stores secrets in AWS Secrets Manager and provides ConfigMap values for ArgoCD

include "root" {
  path   = find_in_parent_folders("includes/stack-config.hcl")
  expose = true
}

terraform {
  source = "git::https://github.com/honeyhiveai/honeyhive-terraform.git//application/aws/secrets_configs?ref=${include.root.locals.terraform_ref}"
}

# Optional dependencies - secrets_configs can work with or without these modules
# When modules are disabled (via stack skip), these dependencies are ignored
dependency "database" {
  config_path = "../database"

  mock_outputs = {
    db_address              = null
    db_port                 = null
    db_name                 = null
    db_username             = null
    db_password_secret_name = null
    db_password_secret_arn  = null
  }

  skip_outputs = false
}

dependency "ecr" {
  config_path = "../ecr"

  mock_outputs = {
    repository_urls = {}
  }

  skip_outputs = false
}

# IAM dependency (optional - if IAM unit is skipped)
dependency "iam" {
  config_path = "../iam"

  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan"]
  mock_outputs = {
    cp_writer_role_arn      = "arn:aws:iam::123456789012:role/mockCpWriter"
    cp_controller_role_arn  = "arn:aws:iam::123456789012:role/mockCpController"
    cp_backend_role_arn     = "arn:aws:iam::123456789012:role/mockCpBackend"
    cp_notification_role_arn = "arn:aws:iam::123456789012:role/mockCpNotification"
    cp_frontend_role_arn    = "arn:aws:iam::123456789012:role/mockCpFrontend"
    dp_ingestion_role_arn   = "arn:aws:iam::123456789012:role/mockDpIngestion"
    dp_controller_role_arn  = "arn:aws:iam::123456789012:role/mockDpController"
    dp_evaluation_role_arn  = "arn:aws:iam::123456789012:role/mockDpEvaluation"
    dp_backend_role_arn     = "arn:aws:iam::123456789012:role/mockDpBackend"
    dp_pythonmetric_role_arn = "arn:aws:iam::123456789012:role/mockDpPythonMetric"
    dp_llmproxy_role_arn    = "arn:aws:iam::123456789012:role/mockDpLlmProxy"
  }

  skip_outputs = false
}

inputs = {
  # Core variables
  org        = include.root.locals.org
  env        = include.root.locals.env
  region     = include.root.locals.region
  sregion    = include.root.locals.sregion
  deployment = include.root.locals.deployment
  account_id = include.root.locals.account_id

  # Module outputs (when modules are enabled)
  database_outputs = {
    db_address              = try(dependency.database.outputs.db_address, null)
    db_port                 = try(dependency.database.outputs.db_port, null)
    db_name                 = try(dependency.database.outputs.db_name, null)
    db_username             = try(dependency.database.outputs.db_username, null)
    db_password_secret_name = try(dependency.database.outputs.db_password_secret_name, null)
    db_password_secret_arn  = try(dependency.database.outputs.db_password_secret_arn, null)
  }

  ecr_outputs = {
    repository_urls = try(dependency.ecr.outputs.repository_urls, {})
  }

  # IAM outputs (optional)
  iam_outputs = try(dependency.iam.outputs, null) != null ? {
    cp_writer_role_arn      = try(dependency.iam.outputs.cp_writer_role_arn, null)
    cp_controller_role_arn  = try(dependency.iam.outputs.cp_controller_role_arn, null)
    cp_backend_role_arn     = try(dependency.iam.outputs.cp_backend_role_arn, null)
    cp_notification_role_arn = try(dependency.iam.outputs.cp_notification_role_arn, null)
    cp_frontend_role_arn    = try(dependency.iam.outputs.cp_frontend_role_arn, null)
    dp_ingestion_role_arn   = try(dependency.iam.outputs.dp_ingestion_role_arn, null)
    dp_controller_role_arn  = try(dependency.iam.outputs.dp_controller_role_arn, null)
    dp_evaluation_role_arn  = try(dependency.iam.outputs.dp_evaluation_role_arn, null)
    dp_backend_role_arn     = try(dependency.iam.outputs.dp_backend_role_arn, null)
    dp_pythonmetric_role_arn = try(dependency.iam.outputs.dp_pythonmetric_role_arn, null)
    dp_llmproxy_role_arn    = try(dependency.iam.outputs.dp_llmproxy_role_arn, null)
  } : null

  # User config overrides (when modules are disabled - passed from config file)
  # These can be set via config file when database/ecr units are skipped
  database_address   = try(include.root.locals.cfg.database_address, null)
  database_port      = try(include.root.locals.cfg.database_port, null)
  database_name      = try(include.root.locals.cfg.database_name, null)
  database_username  = try(include.root.locals.cfg.database_username, null)
  database_password  = try(include.root.locals.cfg.database_password, null)
  ecr_repository_urls = try(include.root.locals.cfg.ecr_repository_urls, null)

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
    Service      = "secrets-configs"
  }
}

