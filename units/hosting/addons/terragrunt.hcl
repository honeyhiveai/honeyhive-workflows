# EKS Addons Unit - Cluster addons and controllers

include "root" {
  path   = find_in_parent_folders("includes/stack-config.hcl")
  expose = true
}

# Dependencies for execution order - addons only need cluster to be ready
dependencies {
  paths = [
    "../cluster"
  ]
}

# DNS zone name computed locally (same formula as substrate stack)
locals {
  dns_zone_name = "${include.root.locals.deployment}.${include.root.locals.sregion}.${include.root.locals.env}.${include.root.locals.cfg.shortname}.${include.root.locals.cfg.domain_name}"
}

# Mock outputs for cluster dependency (needed for first deployment)
dependency "cluster" {
  config_path = "../cluster"

  # Mock outputs for first deployment when cluster doesn't exist yet
  mock_outputs = {
    cluster_name      = "${include.root.locals.org}-${include.root.locals.env}-${include.root.locals.sregion}-${include.root.locals.deployment}"
    cluster_endpoint  = "https://${include.root.locals.org}-${include.root.locals.env}-${include.root.locals.sregion}-${include.root.locals.deployment}.gr7.${include.root.locals.region}.eks.amazonaws.com"
    cluster_certificate_authority_data = "LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSURCVENDQWUyZ0F3SUJBZ0lJT3l5VDN1RzJFUDh3RFFZSktvWklodmNOQVFFTEJRQXdGVEVUTUJFR0ExVUUKQXhNS2EzVmlaWEp1WlhSbGN6QWVGdzB5TlRFd01qRXdPVEUwTVRKYUZ3MHpOVEV3TVRrd09URTVNVEphTUJVeApFekFSQmdOVkJBTVRDbXQxWW1WeWJtVjBaWE13Z2dFaU1BMEdDU3FHU0liM0RRRUJBUVVBQTRJQkR3QXdnZ0VLCkFvSUJBUUM4TDZvcE85ak1XaXg3VjNzcGp5SE96blkyZEJhYTBQMUxRRzNRRGZUOWV4cUxSNFdETE5nNXNjYjkKbU1XTWpxMWhucnova2crUXB1b3krU25VM1U0OVBTd1haaHNJb0xTTVAzVGNTT3k4cUN2b1R1SDdFRE9oMS9zcgpuMy85TStJWjM5WDBRUHBJZzU3NlU5SEhLbERLRUoxMzNEY0pyKzRqYjIxQ2NkM0I5NlppSW9yOXRVNHN6VXloCmRETFpBNG5uSmNvQXpadnVaaEFIVE9LTHpVNG9TeEFHZGplVUlXZ2VYVzFpNmhQemk1MmtsUjZVcTk2MllRYk8KWXpWdDU2bjBPbWtkd3N0NmptR3FzVzJLNWtVY3RFWHpReDV5MGF6eFZRbFBIZUR0VW5jZzVZdnY1eVZYSjhZQgoxOXhNTWgrZkk0Tm5OSkFaaUowL3puamtMSStaQWdNQkFBR2pXVEJYTUE0R0ExVWREd0VCL3dRRUF3SUNwREFQCkJnTlZIUk1CQWY4RUJUQURBUUgvTUIwR0ExVWREZ1FXQkJUWXd1Ukw3T2RxeW5JY2ZBZWl3MXMzcmxnMGRUQVYKQmdOVkhSRUVEakFNZ2dwcmRXSmxjbTVsZEdWek1BMEdDU3FHU0liM0RRRUJDd1VBQTRJQkFRQWZON0tlaGp5NApzeWtaS0lXdHU3dkpMaUxpUmZrZFJ6cU1rcnJYN2xBa1A0cTdKK3dPWnB6U2tCbGpNbk91eUFLL1lXdzBpUDl1CklWNE1GdkRiRGdvNFV1akRlVWQ3QmlwMWJKeXF2ZFBicExjZTd2anp0S2kzR1owOTcrMHN6Sk9WeFpwMWhmdnEKTCtzTE41KzVocXJNWS8yV1kwbE5uSVVrSGRPRFlmODNzTjQ5Rm5CZS9US0x6K2VoUVlMUXVQUXh1eVFHaElMdAovaFZicjNpS0dGUkF3SWNyRTl2N3JxbFJwejdUdmhWaytiZGRKaGVZY2w3eWhwNEgzd1dHZUpTM1hBY05weTJiCktueWhkMmZ0WHphaExIMEhVSktxSWIyVnZzclJUT2JZSlh5UmdGb0pZcHh3dzY2MjZVUDdCaTZtMzQ2ZkVaazIKblhUOTlBVzFRQzBBCi0tLS0tRU5EIENFUlRJRklDQVRFLS0tLS0K"
    oidc_provider_arn = "arn:aws:iam::${include.root.locals.account_id}:oidc-provider/oidc.eks.${include.root.locals.region}.amazonaws.com/id/00000000000000000000000000000000"
  }

  # Skip outputs during destroy to avoid dependency issues
  skip_outputs = false
}

terraform {
  source = "git::https://github.com/honeyhiveai/honeyhive-terraform.git//hosting/aws/kubernetes/addons?ref=${include.root.locals.terraform_ref}"
}

inputs = {
  # Core variables
  org        = include.root.locals.org
  env        = include.root.locals.env
  region     = include.root.locals.region
  sregion    = include.root.locals.sregion
  deployment = include.root.locals.deployment
  account_id = include.root.locals.account_id

  layer   = "hosting"
  service = "addons"

  # State bucket for remote state lookups (fallback only)
  state_bucket             = try(include.root.locals.cfg.state_bucket, "honeyhive-federated-${include.root.locals.sregion}-state")
  orchestration_account_id = try(include.root.locals.cfg.orchestration_account_id, "839515361289")

  # Cluster info - computed from config (dependency outputs don't work during destroy!)
  # cluster_name computes to: org-env-sregion-deployment
  cluster_name    = dependency.cluster.outputs.cluster_name
  cluster_version = try(include.root.locals.cfg.cluster_version, "1.32")

  # Use dependency outputs (with mock fallbacks for first deployment)
  cluster_endpoint  = dependency.cluster.outputs.cluster_endpoint
  cluster_certificate_authority_data = dependency.cluster.outputs.cluster_certificate_authority_data
  oidc_provider_arn = dependency.cluster.outputs.oidc_provider_arn

  # Don't pass these - module computes them from naming convention (eliminates chicken-and-egg)
  # iam_role_arns - computed as: arn:aws:iam::ACCOUNT:role/${iam_prefix}${RoleName}
  # karpenter_node_instance_profile_name - computed as: ${iam_prefix}KarpenterNode

  dns_zone_name = local.dns_zone_name # Computed locally using same formula as substrate

  # Feature flags
  deploy_argocd       = try(include.root.locals.cfg.deploy_argocd, true)
  enable_karpenter    = try(include.root.locals.cfg.enable_karpenter, true)
  enable_monitoring   = try(include.root.locals.cfg.enable_monitoring, false)
  enable_external_dns = try(include.root.locals.cfg.enable_external_dns, false)
  enable_velero       = try(include.root.locals.cfg.enable_velero, false)
  enable_fluent_bit   = try(include.root.locals.cfg.enable_fluent_bit, false)

  # Configuration
  eso_namespace          = try(include.root.locals.cfg.eso_namespace, "external-secrets")
  node_instance_types    = try(include.root.locals.cfg.node_instance_types, ["m5.large", "m5.xlarge"])
  logging_retention_days = try(include.root.locals.cfg.logging_retention_days, 30)
}

