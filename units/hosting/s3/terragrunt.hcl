# Hosting S3 Observability Storage Unit - OpenTelemetry, Prometheus, Grafana Storage

include "root" {
  path   = find_in_parent_folders("includes/stack-config.hcl")
  expose = true
}

terraform {
  source = "git::https://github.com/honeyhiveai/honeyhive-terraform.git//hosting/aws/s3?ref=${include.root.locals.terraform_ref}"
}

inputs = {
  # Core variables
  org        = include.root.locals.org
  env        = include.root.locals.env
  region     = include.root.locals.region
  sregion    = include.root.locals.sregion
  deployment = include.root.locals.deployment
}

