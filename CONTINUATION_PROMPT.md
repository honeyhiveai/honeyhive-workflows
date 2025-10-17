# Continuation Prompt - Terragrunt Stacks Architecture Implementation

## Current Status (October 17, 2025)

### ✅ **Fully Deployed and Working**
- **Substrate Stack** (VPC + DNS + Twingate) - 100% successful in AWS
- **Terragrunt Stacks Architecture** - Modern architecture fully implemented
- **Authentication Chain** - GitHub App → OIDC → Federated → Provisioner working
- **CLI Tooling** - Click/Rich-based `select-stack.py` with externalized configs

### 🔧 **In Progress - Hosting Layer**
- **Cluster** - EKS module ready, needs testing
- **Karpenter** - Remote state issues FIXED (v0.2.14), uses dependency outputs
- **Pod-identities** - Policy path issues FIXED (v0.2.15), uses `${path.module}`
- **Addons** - Needs same policy path fixes as pod-identities

### 📦 **Current Versions**
- `honeyhive-workflows`: v0.26.1
- `honeyhive-terraform`: v0.2.15
- `tf-module-aws-iam`: v2.4.2
- `apiary`: main

## Key Learnings & Patterns

### 1. Terragrunt Stacks Limitations

**Nested includes not supported:**
```hcl
# ❌ Don't do this
include "aws_provider" { ... }  # which includes tenant_config
include "tenant_config" { ... }

# ✅ Do this  
include "root" {
  path = "includes/stack-config.hcl"  # Everything in one file
}
```

**Solution**: Created `stack-config.hcl` that combines all configuration inline.

### 2. Remote State vs Dependencies

Modules using `data "terraform_remote_state"` fail because Stacks use different state paths.

**Solution**: Pass values as optional variables:
```hcl
# In module variables.tf
variable "cluster_name" { default = null }

# In module main.tf
locals {
  cluster_name = var.cluster_name != null ? var.cluster_name : data.terraform_remote_state.cluster.outputs.cluster_name
}

# In unit terragrunt.hcl
dependency "cluster" { config_path = "../cluster" }
inputs = { cluster_name = dependency.cluster.outputs.cluster_name }
```

### 3. Policy File Paths

`file()` function resolves relative to execution directory (`.terragrunt-stack/unit/`), not module source.

**Solution**: Use `${path.module}` for absolute paths:
```hcl
role_policies = ["${path.module}/identity_policies/policy.json"]
```

### 4. Input Patterns

**Don't merge entire config** - causes null values:
```hcl
# ❌ Wrong
inputs = merge(include.root.locals.cfg, { layer = "substrate" })

# ✅ Right
inputs = {
  org     = include.root.locals.org
  env     = include.root.locals.env
  vpc_cidr = include.root.locals.cfg.vpc_cidr
}
```

### 5. Provider Configuration

**For special providers** (Twingate, Helm), generate in the unit:
```hcl
generate "twingate_provider" {
  path = "twingate_provider.tf"
  contents = <<EOF
provider "twingate" {
  api_token = "${get_env("TWINGATE_API_TOKEN")}"
  network   = "${include.root.locals.cfg.twingate_network}"
}
EOF
}
```

## What Still Needs Work

### Immediate: Hosting Layer Completion

1. **Addons Module** - Apply same `${path.module}` fix as pod-identities
2. **Test cluster deployment** - Should work now
3. **Test karpenter** - Remote state fixed, should work  
4. **Test addons** - After path fix
5. **Test pod-identities** - After path fix

### Module Updates Needed

**In `hosting/aws/kubernetes/addons/main.tf`:**
- Same `${path.module}` prefix for all policy file references
- Possibly needs cluster outputs as optional variables (like Karpenter)

**In `hosting/aws/kubernetes/cluster/main.tf`:**
- Already uses IAM v2.4.2 ✅
- May need VPC outputs passed as variables instead of data source lookups

### Testing Strategy

1. Deploy hosting stack: `stack=hosting`, `action=plan`
2. Check which units fail
3. Fix module issues
4. Tag new version
5. Re-deploy

## Authentication & Permissions

### HoneyhiveFederatedProvisioner Role

Located in: `apiary/orchestration/infrastructure/iam/`

**Required Permissions:**
- ✅ Secrets Manager (Create, Update, Delete)
- ✅ KMS (Decrypt, GenerateDataKey, Encrypt, CreateGrant)
- ✅ STS (AssumeRole to target accounts)
- ✅ S3 (State management)
- ✅ DynamoDB (State locking)
- ✅ IAM (Role/Policy management)

**Applied to AWS**: Yes, policy updated on Oct 17, 2025

### KMS Key Policy

Located in: `apiary/orchestration/infrastructure/usw2/kms/`

Allows:
- Secrets Manager service to use key
- Target account roles (*TwingateECSTaskExecution, *ExternalSecretsOperator)
- ECS tasks via ViaService condition

## Configuration Files

### test-usw2-app03.yaml

**Working Configuration:**
```yaml
org: honeyhive
env: test
region: us-west-2
sregion: usw2
deployment: app03
account_id: "982081090170"
deployment_type: full_stack

vpc_cidr: 10.21.0.0/16
domain_name: honeyhive.comb
dns_zone_name: app03.usw2.test.hh.honeyhive.comb

twingate_network: honeyhiveai
twingate_group_id: "R3JvdXA6NDExNjE2"  # Base64-encoded, not g-xxx format

cluster_version: "1.32"
```

## Next Session Tasks

1. **Fix Addons Module** - Add `${path.module}` to policy paths
2. **Test Hosting Stack** - Deploy cluster + karpenter + addons + pod-identities
3. **Fix any remote state issues** - Add optional variables like Karpenter
4. **Deploy Application Layer** - S3 and database modules
5. **Test Full Stack** - All layers together
6. **Document Final Architecture** - Complete guide

## Quick Start Commands for Next Session

```bash
# Check current status
cd /home/honeyhive/Projects/apiary
gh run list --workflow="deploy-infrastructure-stacks.yml" --limit 5

# Deploy hosting (after fixes)
gh workflow run deploy-infrastructure-stacks.yml \
  -f environment=test-usw2-app03 \
  -f stack=hosting \
  -f action=plan \
  -f terraform_ref=v0.2.15

# Check what needs fixing
cd /home/honeyhive/Projects/honeyhive-terraform
grep -r "role_policies.*identity_policies" hosting/aws/kubernetes/addons/

# Apply fixes, commit, tag
git add hosting/
git commit -m "fix: Add path.module to addons policy paths #patch"
git push
git tag v0.2.16
git push origin v0.2.16
```

## Key Files to Review

- `honeyhive-workflows/includes/stack-config.hcl` - Single include with all config
- `honeyhive-workflows/stacks/aws/*/terragrunt.stack.hcl` - Stack definitions
- `honeyhive-terraform/hosting/aws/kubernetes/cluster/main.tf` - EKS cluster module
- `apiary/configs/test-usw2-app03.yaml` - Test environment config
- `apiary/orchestration/infrastructure/iam/` - Federated role with KMS permissions

## Success Metrics

**Substrate**: ✅ 100% deployed
- VPC with 10.21.0.0/16
- Route53 zone: app03.usw2.test.hh.honeyhive.comb
- Twingate VPN connector running on ECS

**Hosting**: 🔄 In progress (1 of 4 units succeeded in last test)
**Application**: ⏳ Not started

## Architecture Documentation

See:
- `STACK_ARCHITECTURE.md` - Full architecture guide
- `DEPLOYMENT_TYPES.md` - Deployment type patterns
- `scripts/select-stack.py --help` - CLI tool documentation
- `stacks/deployment-types/configs/README.md` - Config guide

---

**Status**: Terragrunt Stacks architecture is working. Substrate deployed successfully. Hosting layer needs module updates for policy paths and remote state compatibility. Continue with fixing addons module and testing full hosting stack deployment.

