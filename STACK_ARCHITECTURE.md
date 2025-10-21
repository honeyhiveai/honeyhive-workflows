# Terragrunt Stacks Architecture

## Overview

This repository implements a modern **Terragrunt Stacks** architecture for deploying HoneyHive infrastructure across multiple cloud environments with explicit dependency management and enterprise-scale multi-tenant support.

## Architecture Principles

### 1. Terragrunt Stacks (v0.91.1+)

We use Terragrunt's Stack feature for explicit dependency orchestration:

```
stacks/aws/
├── substrate/terragrunt.stack.hcl  # Foundation layer
├── hosting/terragrunt.stack.hcl    # Platform layer  
├── application/terragrunt.stack.hcl # Workload layer
└── full/terragrunt.stack.hcl       # All layers orchestrated
```

### 2. Unit-Based Organization

Each infrastructure component is a self-contained "unit":

```
units/
├── substrate/
│   ├── vpc/          # Network foundation
│   ├── dns/          # Private DNS
│   └── twingate/     # VPN access
├── hosting/
│   ├── cluster/      # EKS cluster
│   ├── karpenter/    # Autoscaling
│   ├── addons/       # K8s addons
│   └── pod-identities/ # IAM for K8s
└── application/
    ├── database/     # RDS/DocumentDB
    └── s3/           # Object storage
```

### 3. Flattened Includes (Single-Level Only)

Terragrunt Stacks **only supports one level of includes**. We use `stack-config.hcl` which combines:

- Tenant configuration loading (YAML)
- Remote state configuration (S3)
- AWS provider generation

**Don't do this** (nested includes fail in Stacks):

```hcl
# ❌ aws-provider.hcl includes tenant-config.hcl
include "tenant_config" { ... }
include "aws_provider" { ... }  # This tries to include tenant_config again
```

**Do this** (single-level):

```hcl
# ✅ One include with everything
include "root" {
  path = find_in_parent_folders("includes/stack-config.hcl")
}
```

### 4. Explicit Dependencies

Dependencies are managed via `dependency` blocks in units, not implicit scanning:

```hcl
# units/substrate/dns/terragrunt.hcl
dependency "vpc" {
  config_path = "../vpc"
  mock_outputs = { vpc_id = "mock-vpc-id" }
}

inputs = {
  vpc_id = dependency.vpc.outputs.vpc_id
}
```

### 5. Deployment Type Configurations

Externalized YAML configs in `stacks/deployment-types/configs/`:

```yaml
# control_plane.yaml
name: control_plane
description: API, dashboard, and GitOps management
stack_file: stacks/deployment-types/control-plane.stack.yaml
components:
  - substrate
  - hosting
  - application
features:
  - monitoring
  - argocd
disabled_features:
  - twingate
  - karpenter
```

Platform engineers can add/modify deployment types without code changes.

## Directory Structure

```
honeyhive-workflows/
├── .github/workflows/
│   ├── terragrunt-stack-deploy.yml  # Reusable workflow for Stacks
│   └── test-stack-selector.yml      # Tests for CLI tooling
├── actions/
│   ├── setup-terragrunt/            # Install Terragrunt
│   └── setup-python-tools/          # Install PyYAML, Rich, Click
├── stacks/
│   ├── aws/
│   │   ├── substrate/terragrunt.stack.hcl
│   │   ├── hosting/terragrunt.stack.hcl
│   │   ├── application/terragrunt.stack.hcl
│   │   └── full/terragrunt.stack.hcl
│   └── deployment-types/
│       ├── configs/                  # YAML deployment configs
│       │   ├── full_stack.yaml
│       │   ├── control_plane.yaml
│       │   ├── data_plane.yaml
│       │   ├── federated_byoc.yaml
│       │   └── hybrid_saas.yaml
│       └── *.stack.hcl              # Type-specific stacks
├── units/
│   ├── substrate/
│   │   ├── vpc/terragrunt.hcl
│   │   ├── dns/terragrunt.hcl
│   │   └── twingate/terragrunt.hcl
│   ├── hosting/
│   │   ├── cluster/terragrunt.hcl
│   │   ├── karpenter/terragrunt.hcl
│   │   ├── addons/terragrunt.hcl
│   │   └── pod-identities/terragrunt.hcl
│   └── application/
│       ├── database/terragrunt.hcl
│       └── s3/terragrunt.hcl
├── includes/
│   ├── stack-config.hcl              # Flattened config (CRITICAL)
│   ├── tenant-config.hcl             # Legacy (for non-Stack workflows)
│   ├── aws-provider.hcl              # Legacy (for non-Stack workflows)
│   └── remote-state.hcl              # Legacy (for non-Stack workflows)
└── scripts/
    ├── select-stack.py               # CLI tool (Click + Rich)
    ├── validate-stacks.sh            # Structure validator
    └── requirements.txt              # Python dependencies

```

## Stack Files

Stack files use HCL format (`.hcl` not `.yaml`) and define units:

```hcl
# stacks/aws/substrate/terragrunt.stack.hcl
unit "vpc" {
  source = "../../../units/substrate/vpc"
  path   = "vpc"
}

unit "dns" {
  source = "../../../units/substrate/dns"
  path   = "dns"
}

unit "twingate" {
  source = "../../../units/substrate/twingate"
  path   = "twingate"
}
```

**Important**:

- Path must match what dependency `config_path` expects
- No `dependencies = []` attribute (managed in units)
- Dependencies resolved via `dependency` blocks in units

## Deployment Commands

```bash
# Set configuration
export TENANT_CONFIG_PATH="/path/to/config.yaml"

# Deploy a specific stack
cd stacks/aws/substrate
terragrunt stack run init
terragrunt stack run plan
terragrunt stack run apply

# Via GitHub Actions
# Actions → Deploy Infrastructure (Stacks)
# Select: environment, stack, action
```

## CLI Tooling

### Stack Selector (Python + Click + Rich)

```bash
# List all deployment types
./scripts/select-stack.py --list

# Select stack for a config
./scripts/select-stack.py configs/production.yaml

# Override deployment type
./scripts/select-stack.py configs/test.yaml -t control_plane

# JSON output for automation
./scripts/select-stack.py configs/prod.yaml --json

# Validate only
./scripts/select-stack.py configs/staging.yaml --validate-only
```

## Unit Configuration Pattern

Each unit follows this structure:

```hcl
# units/substrate/vpc/terragrunt.hcl

# Single include with everything
include "root" {
  path   = find_in_parent_folders("includes/stack-config.hcl")
  expose = true
}

# Terraform module source
terraform {
  source = "git::https://github.com/honeyhiveai/honeyhive-terraform.git//substrate/aws/vpc?ref=${include.root.locals.terraform_ref}"
}

# Explicit inputs (NOT merge - causes null values)
inputs = {
  org        = include.root.locals.org
  env        = include.root.locals.env
  region     = include.root.locals.region
  sregion    = include.root.locals.sregion
  deployment = include.root.locals.account_id
  
  # Module-specific inputs
  vpc_cidr = include.root.locals.cfg.vpc_cidr
}
```

**Key Points:**

- ✅ Use explicit `inputs = { ... }`
- ❌ Don't use `merge(include.root.locals.cfg, {...})` - causes null values
- ✅ Reference config via `include.root.locals.cfg.xxx`
- ✅ Use `try()` for optional values with defaults

## Provider Generation

Providers are generated in `includes/stack-config.hcl`:

```hcl
generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  
  contents = <<EOF
provider "aws" {
  region = "${local.region}"
  
  assume_role {
    role_arn     = "arn:aws:iam::${local.account_id}:role/HoneyhiveProvisioner"
    session_name = "terragrunt-${local.env}-${local.deployment}"
    external_id  = "honeyhive-deployments-${local.env}"
  }
  
  allowed_account_ids = ["${local.account_id}"]
  
  default_tags {
    tags = {
      Organization = "${local.org}"
      Environment  = "${local.env}"
      # ...
    }
  }
}
EOF
}
```

**Don't generate** providers that modules define themselves (like `aws.orchestration` for Twingate).

## Authentication Chain

GitHub Actions → OIDC → HoneyhiveFederatedProvisioner → HoneyhiveProvisioner (target account)

```yaml
# In workflow
- name: Configure AWS Credentials
  uses: aws-actions/configure-aws-credentials@v4
  with:
    role-to-assume: ${{ vars.AWS_OIDC_ROLE }}  # HoneyhiveFederatedProvisioner
    aws-region: ${{ steps.extract_config.outputs.region }}
```

The Federated role needs:

- Secrets Manager permissions (create, update secrets)
- KMS permissions (Decrypt, GenerateDataKey, Encrypt, CreateGrant)
- STS permissions (AssumeRole to target accounts)

## Common Patterns

### Passing Dependency Outputs

```hcl
dependency "cluster" {
  config_path = "../cluster"
}

inputs = {
  cluster_name     = dependency.cluster.outputs.cluster_name
  cluster_endpoint = dependency.cluster.outputs.cluster_endpoint
}
```

### Overriding Remote State Lookups

When modules use `data "terraform_remote_state"` for old path structures, pass values as variables:

```hcl
# In Terraform module variables.tf
variable "cluster_name" {
  type    = string
  default = null  # Optional override
}

# In module main.tf locals
locals {
  cluster_name = var.cluster_name != null ? var.cluster_name : data.terraform_remote_state.cluster.outputs.cluster_name
}
```

### Policy File Paths

Always use `${path.module}` for policy files:

```hcl
# ❌ Wrong (breaks in Stacks)
role_policies = ["identity_policies/policy.json"]

# ✅ Correct
role_policies = ["${path.module}/identity_policies/policy.json"]
```

### Provider Configuration

For special providers (Twingate, Helm, etc.), generate in the unit:

```hcl
# units/substrate/twingate/terragrunt.hcl
generate "twingate_provider" {
  path      = "twingate_provider.tf"
  if_exists = "overwrite_terragrunt"
  contents = <<EOF
provider "twingate" {
  api_token = "${get_env("TWINGATE_API_TOKEN")}"
  network   = "${include.root.locals.cfg.twingate_network}"
}
EOF
}
```

## Troubleshooting

### Stack Command Syntax

```bash
# ✅ Correct
terragrunt stack run init
terragrunt stack run plan
terragrunt stack run apply
terragrunt stack run destroy

# ❌ Wrong
terragrunt stack init --stack file.yaml
terragrunt stack run --terragrunt-non-interactive apply
```

### Non-Interactive Mode

Use environment variables, not flags:

```yaml
env:
  TF_INPUT: 'false'
  TF_IN_AUTOMATION: '1'
  TERRAFORM_REF: 'v0.2.15'
```

### Version Management

```hcl
# In stack-config.hcl
terraform_ref = try(
  local.cfg.terraform_ref,        # 1. From config file
  get_env("TERRAFORM_REF", "v0.2.15")  # 2. From env or default
)
```

Pass via workflow:

```yaml
env:
  TERRAFORM_REF: ${{ inputs.terraform_ref }}
```

### Null Value Errors

Use explicit inputs, not merge:

```hcl
# ❌ Causes null values
inputs = merge(include.root.locals.cfg, { ... })

# ✅ Explicit and safe
inputs = {
  org = include.root.locals.org
  vpc_cidr = include.root.locals.cfg.vpc_cidr
}
```

## Deployment Types

Five enterprise deployment patterns supported:

1. **full_stack** - Complete platform (all features)
2. **control_plane** - API, dashboard, GitOps management
3. **data_plane** - Compute workloads only
4. **federated_byoc** - Customer's cloud, HoneyHive managed
5. **hybrid_saas** - Control in HoneyHive, data in customer

Configured via YAML in `stacks/deployment-types/configs/`.

## Version History

- **v0.15.0** - Initial Stacks architecture
- **v0.20.0** - Flattened includes, Git credentials
- **v0.22.0** - TF_INPUT env vars  
- **v0.24.0** - TERRAFORM_REF env var support
- **v0.25.0** - Removed -next suffix, clean architecture
- **v0.26.1** - Current stable (Karpenter dependency fixes)

## References

- [Terragrunt Stacks Documentation](https://terragrunt.gruntwork.io/docs/features/stacks/)
- [Stack Run Commands](https://terragrunt.gruntwork.io/docs/reference/cli/commands/stack/run/)
- [Multiple Includes](https://terragrunt.gruntwork.io/docs/features/includes/)

---

*Last Updated: October 2025*
*Architecture: Modern Terragrunt Stacks with explicit dependencies*
