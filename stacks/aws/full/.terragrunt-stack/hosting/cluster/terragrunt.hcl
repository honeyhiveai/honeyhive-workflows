# EKS Cluster Unit - Kubernetes control plane and Fargate profile

include "root" {
  path   = find_in_parent_folders("includes/stack-config.hcl")
  expose = true
}

terraform {
  source = "git::https://github.com/honeyhiveai/honeyhive-terraform.git//hosting/aws/kubernetes/cluster?ref=${include.root.locals.terraform_ref}"
}

inputs = {
  # Core variables
  org            = include.root.locals.org
  env            = include.root.locals.env
  region         = include.root.locals.region
  sregion        = include.root.locals.sregion
  deployment     = include.root.locals.deployment
  aws_account_id = include.root.locals.account_id
  aws_partition  = try(include.root.locals.cfg.aws_partition, "aws")

  layer   = "hosting"
  service = "cluster"

  # EKS Configuration
  cluster_version = try(include.root.locals.cfg.cluster_version, "1.32")

  # EKS Access (optional)
  eks_admin_principal_arns    = try(include.root.locals.cfg.eks_admin_principal_arns, [])
  eks_readonly_principal_arns = try(include.root.locals.cfg.eks_readonly_principal_arns, [])
  eks_access_external_id      = try(include.root.locals.cfg.eks_access_external_id, "")
}

