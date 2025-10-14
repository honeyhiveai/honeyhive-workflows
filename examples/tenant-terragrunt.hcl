# Example Terragrunt configuration for a tenant stack
# This file should be placed in apiary/{org}/{sregion}/terragrunt.hcl

# Include the shared AWS overlay from the catalog
# The _catalog directory is created by the reusable workflow when overlay_ref is specified
include "root" {
  path = "${get_repo_root()}/_catalog/overlays/aws/root.hcl"
}

# Load the tenant configuration
locals {
  cfg = yamldecode(file("${get_terragrunt_dir()}/tenant.yaml"))
}

# Specify the Terraform root module to use
terraform {
  # Example: EKS cluster from the hosting layer
  source = "git::https://github.com/honeyhiveai/honeyhive-terraform.git//hosting/aws/kubernetes/cluster?ref=v1.0.0"
  
  # Alternative examples:
  # VPC from substrate layer:
  # source = "git::https://github.com/honeyhiveai/honeyhive-terraform.git//substrate/aws/vpc?ref=v1.0.0"
  
  # S3 buckets from application layer:
  # source = "git::https://github.com/honeyhiveai/honeyhive-terraform.git//application/aws/s3?ref=v1.0.0"
}

# Pass the configuration to Terraform as inputs
inputs = local.cfg

# Optional: Override specific inputs if needed
# inputs = merge(
#   local.cfg,
#   {
#     custom_parameter = "override_value"
#   }
# )
