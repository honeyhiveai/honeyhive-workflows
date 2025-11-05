# ArgoCD Applications Unit - honeyhive-apps deployment (moved from hosting/)

include "root" {
  path   = find_in_parent_folders("includes/stack-config.hcl")
  expose = true
}

# Note: Cross-stack dependencies for sequencing are handled by full.stack.yaml
# When running standalone application stack, these dependencies are not needed
# The dependency block below is for output passing only (with mock outputs)

terraform {
  source = "git::https://github.com/honeyhiveai/honeyhive-terraform.git//application/aws/kubernetes/argocd_apps?ref=${include.root.locals.terraform_ref}"
}

# Cross-stack dependency on hosting/cluster
# Use mock outputs when running standalone application stack
dependency "cluster" {
  config_path = "../../hosting/cluster"

  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan", "apply", "destroy"]
  mock_outputs = {
    cluster_name                      = "${include.root.locals.org}-${include.root.locals.env}-${include.root.locals.sregion}-${include.root.locals.deployment}"
    cluster_endpoint                  = "https://${include.root.locals.org}-${include.root.locals.env}-${include.root.locals.sregion}-${include.root.locals.deployment}.gr7.${include.root.locals.region}.eks.amazonaws.com"
    cluster_certificate_authority_data = "LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSURCVENDQWUyZ0F3SUJBZ0lJT3l5VDN1RzJFUDh3RFFZSktvWklodmNOQVFFTEJRQXdGVEVUTUJFR0ExVUUKQXhNS2EzVmlaWEp1WlhSbGN6QWVGdzB5TlRFd01qRXdPVEUwTVRKYUZ3MHpOVEV3TVRrd09URTVNVEphTUJVeApFekFSQmdOVkJBTVRDbXQxWW1WeWJtVjBaWE13Z2dFaU1BMEdDU3FHU0liM0RRRUJBUVVBQTRJQkR3QXdnZ0VLCkFvSUJBUUM4TDZvcE85ak1XaXg3VjNzcGp5SE96blkyZEJhYTBQMUxRRzNRRGZUOWV4cUxSNFdETE5nNXNjYjkKbU1XTWpxMWhucnova2crUXB1b3krU25VM1U0OVBTd1haaHNJb0xTTVAzVGNTT3k4cUN2b1R1SDdFRE9oMS9zcgpuMy85TStJWjM5WDBRUHBJZzU3NlU5SEhLbERLRUoxMzNEY0pyKzRqYjIxQ2NkM0I5NlppSW9yOXRVNHN6VXloCmRETFpBNG5uSmNvQXpadnVaaEFIVE9LTHpVNG9TeEFHZGplVUlXZ2VYVzFpNmhQemk1MmtsUjZVcTk2MllRYk8KWXpWdDU2bjBPbWtkd3N0NmptR3FzVzJLNWtVY3RFWHpReDV5MGF6eFZRbFBIZUR0VW5jZzVZdnY1eVZYSjhZQgoxOXhNTWgrZkk0Tm5OSkFaaUowL3puamtMSStaQWdNQkFBR2pXVEJYTUE0R0ExVWREd0VCL3dRRUF3SUNwREFQCkJnTlZIUk1CQWY4RUJUQURBUUgvTUIwR0ExVWREZ1FXQkJUWXd1Ukw3T2RxeW5JY2ZBZWl3MXMzcmxnMGRUQVYKQmdOVkhSRUVEakFNZ2dwcmRXSmxjbTVsZEdWek1BMEdDU3FHU0liM0RRRUJDd1VBQTRJQkFRQWZON0tlaGp5NApzeWtaS0lXdHU3dkpMaUxpUmZrZFJ6cU1rcnJYN2xBa1A0cTdKK3dPWnB6U2tCbGpNbk91eUFLL1lXdzBpUDl1CklWNE1GdkRiRGdvNFV1akRlVWQ3QmlwMWJKeXF2ZFBicExjZTd2anp0S2kzR1owOTcrMHN6Sk9WeFpwMWhmdnEKTCtzTE41KzVocXJNWS8yV1kwbE5uSVVrSGRPRFlmODNzTjQ5Rm5CZS9US0x6K2VoUVlMUXVQUXh1eVFHaElMdAovaFZicjNpS0dGUkF3SWNyRTl2N3JxbFJwejdUdmhWaytiZGRKaGVZY2w3eWhwNEgzd1dHZUpTM1hBY05weTJiCktueWhkMmZ0WHphaExIMEhVSktxSWIyVnZzclJUT2JZSlh5UmdGb0pZcHh3dzY2MjZVUDdCaTZtMzQ2ZkVaazIKblhUOTlBVzFRQzBBCi0tLS0tRU5EIENFUlRJRklDQVRFLS0tLS0K"
  }

  skip_outputs = true  # Skip when file doesn't exist (standalone application stack)
}

# Dependency on secrets_configs for IAM roles and ECR URLs
dependency "secrets_configs" {
  config_path = "../secrets_configs"

  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan"]
  mock_outputs = {
    database_password_secret_name = null
    ecr_repository_urls           = {}
    iam_role_arns                 = {}
  }

  skip_outputs = false
}

# State bucket for remote state lookup (cross-stack dependency)
# Note: secrets_configs dependency is used, but we also provide state_bucket
# as a fallback for remote state lookups if dependency is skipped

inputs = {
  # Core deployment parameters
  org        = include.root.locals.org
  env        = include.root.locals.env
  region     = include.root.locals.region
  sregion    = include.root.locals.sregion
  deployment = include.root.locals.deployment
  domain_name = try(include.root.locals.cfg.domain_name, "")
  deployment_type = try(include.root.locals.cfg.deployment_type, "full_stack")

  # Cluster information from dependency
  cluster_name                      = dependency.cluster.outputs.cluster_name
  cluster_endpoint                  = dependency.cluster.outputs.cluster_endpoint
  cluster_certificate_authority_data = dependency.cluster.outputs.cluster_certificate_authority_data

  # ArgoCD Application configuration
  enable_argocd_applications  = try(include.root.locals.cfg.enable_argocd_applications, true)
  honeyhive_argocd_deploy_key = try(get_env("HONEYHIVE_ARGOCD_DEPLOY_KEY", ""), "")
  honeyhive_helm_deploy_key   = try(get_env("HONEYHIVE_HELM_DEPLOY_KEY", ""), "")
  honeyhive_argocd_ref        = try(include.root.locals.cfg.honeyhive_argocd_ref, "main")

  # Secrets and configs from dependency
  secrets_configs = {
    database_password_secret_name = try(dependency.secrets_configs.outputs.database_password_secret_name, null)
    ecr_repository_urls           = try(dependency.secrets_configs.outputs.ecr_repository_urls, {})
    iam_role_arns                 = try(dependency.secrets_configs.outputs.iam_role_arns, {})
  }

  # State bucket for remote state lookup (fallback)
  state_bucket = try(include.root.locals.cfg.state_bucket, "honeyhive-federated-${include.root.locals.sregion}-state")
}

