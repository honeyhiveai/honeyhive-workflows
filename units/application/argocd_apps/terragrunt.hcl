# ArgoCD Applications Unit - Data Stores App-of-Apps deployment

include "root" {
  path   = find_in_parent_folders("includes/stack-config.hcl")
  expose = true
}

terraform {
  source = "git::https://github.com/honeyhiveai/honeyhive-terraform.git//application/aws/kubernetes/argocd_apps?ref=${include.root.locals.terraform_ref}"
}

# Cluster dependency for EKS cluster information
# NOTE: For application layer, we need to read cluster info from remote state
# since the cluster is deployed in the hosting layer
dependency "cluster" {
  config_path = "../../../units/hosting/cluster"

  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan"]
  mock_outputs = {
    cluster_name                      = "${include.root.locals.org}-${include.root.locals.env}-${include.root.locals.sregion}-${include.root.locals.deployment}"
    cluster_endpoint                  = "https://${include.root.locals.org}-${include.root.locals.env}-${include.root.locals.sregion}-${include.root.locals.deployment}.gr7.${include.root.locals.region}.eks.amazonaws.com"
    cluster_certificate_authority_data = "LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSURCVENDQWUyZ0F3SUJBZ0lJT3l5VDN1RzJFUDh3RFFZSktvWklodmNOQVFFTEJRQXdGVEVUTUJFR0ExVUUKQXhNS2EzVmlaWEp1WlhSbGN6QWVGdzB5TlRFd01qRXdPVEUwTVRKYUZ3MHpOVEV3TVRrd09URTVNVEphTUJVeApFekFSQmdOVkJBTVRDbXQxWW1WeWJtVjBaWE13Z2dFaU1BMEdDU3FHU0liM0RRRUJBUVVBQTRJQkR3QXdnZ0VLCkFvSUJBUUM4TDZvcE85ak1XaXg3VjNzcGp5SE96blkyZEJhYTBQMUxRRzNRRGZUOWV4cUxSNFdETE5nNXNjYjkKbU1XTWpxMWhucnova2crUXB1b3krU25VM1U0OVBTd1haaHNJb0xTTVAzVGNTT3k4cUN2b1R1SDdFRE9oMS9zcgpuMy85TStJWjM5WDBRUHBJZzU3NlU5SEhLbERLRUoxMzNEY0pyKzRqYjIxQ2NkM0I5NlppSW9yOXRVNHN6VXloCmRETFpBNG5uSmNvQXpadnVaaEFIVE9LTHpVNG9TeEFHZGplVUlXZ2VYVzFpNmhQemk1MmtsUjZVcTk2MllRYk8KWXpWdDU2bjBPbWtkd3N0NmptR3FzVzJLNWtVY3RFWHpReDV5MGF6eFZRbFBIZUR0VW5jZzVZdnY1eVZYSjhZQgoxOXhNTWgrZkk0Tm5OSkFaaUowL3puamtMSStaQWdNQkFBR2pXVEJYTUE0R0ExVWREd0VCL3dRRUF3SUNwREFQCkJnTlZIUk1CQWY4RUJUQURBUUgvTUIwR0ExVWREZ1FXQkJUWXd1Ukw3T2RxeW5JY2ZBZWl3MXMzcmxnMGRUQVYKQmdOVkhSRUVEakFNZ2dwcmRXSmxjbTVsZEdWek1BMEdDU3FHU0liM0RRRUJDd1VBQTRJQkFRQWZON0tlaGp5NApzeWtaS0lXdHU3dkpMaUxpUmZrZFJ6cU1rcnJYN2xBa1A0cTdKK3dPWnB6U2tCbGpNbk91eUFLL1lXdzBpUDl1CklWNE1GdkRiRGdvNFV1akRlVWQ3QmlwMWJKeXF2ZFBicExjZTd2anp0S2kzR1owOTcrMHN6Sk9WeFpwMWhmdnEKTCtzTE41KzVocXJNWS8yV1kwbE5uSVVrSGRPRFlmODNzTjQ5Rm5CZS9US0x6K2VoUVlMUXVQUXh1eVFHaElMdAovaFZicjNpS0dGUkF3SWNyRTl2N3JxbFJwejdUdmhWaytiZGRKaGVZY2w3eWhwNEgzd1dHZUpTM1hBY05weTJiCktueWhkMmZ0WHphaExIMEhVSktxSWIyVnZzclJUT2JZSlh5UmdGb0pZcHh3dzY2MjZVUDdCaTZtMzQ2ZkVaazIKblhUOTlBVzFRQzBBCi0tLS0tRU5EIENFUlRJRklDQVRFLS0tLS0K"
  }

  skip_outputs = false
}

inputs = {
  # Core deployment parameters
  org        = include.root.locals.org
  env        = include.root.locals.env
  region     = include.root.locals.region
  sregion    = include.root.locals.sregion
  deployment = include.root.locals.deployment

  # Cluster information from dependency
  cluster_name                      = dependency.cluster.outputs.cluster_name
  cluster_endpoint                  = dependency.cluster.outputs.cluster_endpoint
  cluster_certificate_authority_data = dependency.cluster.outputs.cluster_certificate_authority_data

  # ArgoCD Application configuration
  enable_argocd_applications  = try(include.root.locals.cfg.enable_argocd_applications, true)
  honeyhive_argocd_deploy_key = try(get_env("HONEYHIVE_ARGOCD_DEPLOY_KEY", ""), "")
  honeyhive_helm_deploy_key   = try(get_env("HONEYHIVE_HELM_DEPLOY_KEY", ""), "")
  honeyhive_argocd_ref        = try(include.root.locals.cfg.honeyhive_argocd_ref, "main")
}

