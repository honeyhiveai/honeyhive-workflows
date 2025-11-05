# ArgoCD Applications Unit - GitOps application deployment

include "root" {
  path   = find_in_parent_folders("includes/stack-config.hcl")
  expose = true
}

terraform {
  source = "git::https://github.com/honeyhiveai/honeyhive-terraform.git//hosting/aws/kubernetes/argocd_apps?ref=${include.root.locals.terraform_ref}"
}

# Cluster dependency for EKS cluster information
dependency "cluster" {
  config_path = "../cluster"

  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan"]
  mock_outputs = {
    cluster_name      = "${include.root.locals.org}-${include.root.locals.env}-${include.root.locals.sregion}-${include.root.locals.deployment}"
    cluster_endpoint  = "https://${include.root.locals.org}-${include.root.locals.env}-${include.root.locals.sregion}-${include.root.locals.deployment}.gr7.${include.root.locals.region}.eks.amazonaws.com"
    cluster_certificate_authority_data = "LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSURCVENDQWUyZ0F3SUJBZ0lJT3l5VDN1RzJFUDh3RFFZSktvWklodmNOQVFFTEJRQXdGVEVUTUJFR0ExVUUKQXhNS2EzVmlaWEp1WlhSbGN6QWVGdzB5TlRFd01qRXdPVEUwTVRKYUZ3MHpOVEV3TVRrd09URTVNVEphTUJVeApFekFSQmdOVkJBTVRDbXQxWW1WeWJtVjBaWE13Z2dFaU1BMEdDU3FHU0liM0RRRUJBUVVBQTRJQkR3QXdnZ0VLCkFvSUJBUUM4TDZvcE85ak1XaXg3VjNzcGp5SE96blkyZEJhYTBQMUxRRzNRRGZUOWV4cUxSNFdETE5nNXNjYjkKbU1XTWpxMWhucnova2crUXB1b3krU25VM1U0OVBTd1haaHNJb0xTTVAzVGNTT3k4cUN2b1R1SDdFRE9oMS9zcgpuMy85TStJWjM5WDBRUHBJZzU3NlU5SEhLbERLRUoxMzNEY0pyKzRqYjIxQ2NkM0I5NlppSW9yOXRVNHN6VXloCmRETFpBNG5uSmNvQXpadnVaaEFIVE9LTHpVNG9TeEFHZGplVUlXZ2VYVzFpNmhQemk1MmtsUjZVcTk2MllRYk8KWXpWdDU2bjBPbWtkd3N0NmptR3FzVzJLNWtVY3RFWHpReDV5MGF6eFZRbFBIZUR0VW5jZzVZdnY1eVZYSjhZQgoxOXhNTWgrZkk0Tm5OSkFaaUowL3puamtMSStaQWdNQkFBR2pXVEJYTUE0R0ExVWREd0VCL3dRRUF3SUNwREFQCkJnTlZIUk1CQWY4RUJUQURBUUgvTUIwR0ExVWREZ1FXQkJUWXd1Ukw3T2RxeW5JY2ZBZWl3MXMzcmxnMGRUQVYKQmdOVkhSRUVEakFNZ2dwcmRXSmxjbTVsZEdWek1BMEdDU3FHU0liM0RRRUJDd1VBQTRJQkFRQWZON0tlaGp5NApzeWtaS0lXdHU3dkpMaUxpUmZrZFJ6cU1rcnJYN2xBa1A0cTdKK3dPWnB6U2tCbGpNbk91eUFLL1lXdzBpUDl1CklWNE1GdkRiRGdvNFV1akRlVWQ3QmlwMWJKeXF2ZFBicExjZTd2anp0S2kzR1owOTcrMHN6Sk9WeFpwMWhmdnEKTCtzTE41KzVocXJNWS8yV1kwbE5uSVVrSGRPRFlmODNzTjQ5Rm5CZS9US0x6K2VoUVlMUXVQUXh1eVFHaElMdAovaFZicjNpS0dGUkF3SWNyRTl2N3JxbFJwejdUdmhWaytiZGRKaGVZY2w3eWhwNEgzd1dHZUpTM1hBY05weTJiCktueWhkMmZ0WHphaExIMEhVSktxSWIyVnZzclJUT2JZSlh5UmdGb0pZcHh3dzY2MjZVUDdCaTZtMzQ2ZkVaazIKblhUOTlBVzFRQzBBCi0tLS0tRU5EIENFUlRJRklDQVRFLS0tLS0K"
    oidc_provider_arn = "arn:aws:iam::${include.root.locals.account_id}:oidc-provider/oidc.eks.${include.root.locals.region}.amazonaws.com/id/00000000000000000000000000000000"
  }

  skip_outputs = false
}

# Addons dependency to ensure cluster is fully ready with all addons deployed
dependency "addons" {
  config_path = "../addons"

  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan"]
  mock_outputs = {
    # No specific outputs needed, just ensures addons are deployed first
  }

  skip_outputs = false
}

# Cross-stack dependency on application/secrets_configs
# Note: We use Terraform remote state lookups in the module instead of Terragrunt dependency
# This avoids Terragrunt trying to parse files from a different stack during dependency discovery

inputs = {
  # Core deployment parameters
  org             = include.root.locals.org
  env             = include.root.locals.env
  region          = include.root.locals.region
  sregion         = include.root.locals.sregion
  deployment      = include.root.locals.deployment
  domain_name     = try(include.root.locals.cfg.domain_name, "")
  deployment_type = try(include.root.locals.cfg.deployment_type, "full_stack")

  # Cluster information from dependency
  cluster_name                      = dependency.cluster.outputs.cluster_name
  cluster_endpoint                  = dependency.cluster.outputs.cluster_endpoint
  cluster_certificate_authority_data = dependency.cluster.outputs.cluster_certificate_authority_data
  oidc_provider_arn                 = dependency.cluster.outputs.oidc_provider_arn

  # ArgoCD Applications configuration
  enable_argocd_applications  = try(include.root.locals.cfg.enable_argocd_applications, true)
  honeyhive_argocd_deploy_key = try(get_env("HONEYHIVE_ARGOCD_DEPLOY_KEY", ""), "")
  honeyhive_helm_deploy_key   = try(get_env("HONEYHIVE_HELM_DEPLOY_KEY", ""), "")
  honeyhive_argocd_ref        = try(include.root.locals.cfg.honeyhive_argocd_ref, "main")

  # NOTE: secrets_configs and state_bucket removed
  # honeyhive-apps has been moved to application/aws/kubernetes/argocd_apps
}
