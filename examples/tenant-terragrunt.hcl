# ⚠️ DEPRECATED - Tenants no longer manage Terragrunt files!
#
# This file is kept for reference only. In the new federated catalog model:
# - Tenants only create tenant.yaml (configuration data)
# - Dependency graph lives in honeyhive-workflows/graphs/
# - Workflows set TENANT_CONFIG_PATH and execute the graph
#
# See examples/tenant.yaml for the YAML-only tenant configuration approach.
#
# The dependency DAG is centrally managed in honeyhive-workflows:
#   graphs/aws/full/
#   ├── substrate/vpc/terragrunt.hcl
#   ├── substrate/dns/terragrunt.hcl (depends on vpc)
#   ├── hosting/cluster/terragrunt.hcl (depends on vpc)
#   ├── hosting/karpenter/terragrunt.hcl (depends on cluster)
#   ├── hosting/addons/terragrunt.hcl (depends on cluster, karpenter)
#   └── application/database/terragrunt.hcl (depends on vpc, cluster)
#
# Tenants simply:
# 1. Create {org}/{sregion}/tenant.yaml in apiary
# 2. Push changes
# 3. Workflows automatically deploy using the centralized graph
