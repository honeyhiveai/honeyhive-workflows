# HoneyHive Deployment Types Guide

This guide explains the different deployment types available for HoneyHive infrastructure and how to configure them using the modern Terragrunt Stacks architecture.

## Overview

HoneyHive supports multiple deployment patterns to meet different enterprise requirements:

- **Control Plane**: API and management services
- **Data Plane**: Compute and processing workloads
- **Federated BYOC**: Deploy in customer's cloud with HoneyHive management
- **Hybrid SaaS**: Split control/data architecture
- **Full Stack**: Complete platform deployment

## Quick Start

### 1. Choose Your Deployment Type

Determine which deployment pattern fits your needs:

```yaml
# In your config YAML
deployment_type: control_plane  # or data_plane, federated_byoc, etc.
```

### 2. Use the Stack Selector

```bash
# Automatically select the right stack
./scripts/select-stack.sh configs/your-config.yaml

# Or manually choose
terragrunt stack apply --stack stacks/deployment-types/control-plane.stack.yaml
```

## Deployment Types

### Control Plane

**Purpose**: Central management, API, dashboard, and GitOps

**Components**:

- ✅ VPC and DNS
- ✅ EKS cluster (fixed size)
- ✅ Database (control state)
- ✅ ArgoCD (manage data planes)
- ✅ Monitoring (Prometheus/Grafana)
- ❌ Twingate VPN
- ❌ Karpenter auto-scaling

**Use Cases**:

- Multi-region deployments with central management
- Separated control/data architecture
- Compliance requiring control isolation

**Example Config**: [`examples/configs/control-plane.yaml`](examples/configs/control-plane.yaml)

### Data Plane

**Purpose**: Compute workloads, ML processing, batch jobs

**Components**:

- ✅ VPC and DNS
- ✅ EKS cluster (auto-scaling)
- ✅ Karpenter (critical for scaling)
- ✅ S3 (temporary storage)
- ✅ GPU support (optional)
- ❌ Database (uses control plane)
- ❌ ArgoCD (managed remotely)

**Use Cases**:

- High-compute ML workloads
- Batch processing
- Region-specific data processing
- Cost-optimized spot instances

**Example Config**: [`examples/configs/data-plane.yaml`](examples/configs/data-plane.yaml)

### Federated BYOC (Bring Your Own Cloud)

**Purpose**: Deploy in customer's AWS account with full data sovereignty

**Components**:

- ✅ Everything in customer account
- ✅ Customer KMS keys
- ✅ Compliance controls (CloudTrail, Config, GuardDuty)
- ✅ Network isolation (PrivateLink)
- ✅ Data residency enforcement
- ❌ Direct internet access

**Use Cases**:

- Enterprise customers requiring data sovereignty
- Regulated industries (healthcare, finance)
- GDPR/data residency requirements
- Zero-trust security models

**Key Features**:

- Customer owns all data
- HoneyHive manages infrastructure
- Cross-account access with minimal permissions
- Full audit trail
- Customer-controlled encryption

**Example Config**: [`examples/configs/federated-byoc.yaml`](examples/configs/federated-byoc.yaml)

### Hybrid SaaS

**Purpose**: Control plane in HoneyHive cloud, data plane in customer cloud

**Components**:

- **In HoneyHive Cloud**:
  - Control plane API
  - Dashboard
  - GitOps management
  - Central monitoring
  
- **In Customer Cloud**:
  - Data processing
  - Compute workloads
  - Customer data storage
  - PrivateLink connection

**Use Cases**:

- Balance between managed service and data control
- Customers wanting HoneyHive management without data leaving their cloud
- Cost optimization (customer pays for compute)

**Example Config**: [`examples/configs/hybrid-saas.yaml`](examples/configs/hybrid-saas.yaml)

### Full Stack

**Purpose**: Complete HoneyHive platform with all features

**Components**:

- ✅ All substrate components
- ✅ All hosting components
- ✅ All application components
- ✅ All features enabled

**Use Cases**:

- Internal deployments
- Single-tenant dedicated deployments
- Development/testing environments
- Proof of concepts

## Feature Matrix

| Feature | Control Plane | Data Plane | Federated BYOC | Hybrid SaaS | Full Stack |
|---------|--------------|------------|----------------|-------------|------------|
| **Infrastructure** |
| VPC | ✅ | ✅ | ✅ | ✅ | ✅ |
| DNS | ✅ | ✅ | ✅ | ✅ | ✅ |
| Twingate VPN | ❌ | ❌ | Customer VPN | ❌ | ✅ |
| **Kubernetes** |
| EKS Cluster | ✅ | ✅ | ✅ | ✅ | ✅ |
| Karpenter | ❌ | ✅ | Optional | ✅ | ✅ |
| **Data** |
| Database | ✅ | ❌ | ✅ | ❌ | ✅ |
| S3 Storage | ✅ | ✅ | ✅ | ✅ | ✅ |
| **Features** |
| Monitoring | ✅ | Forward | Limited | Forward | ✅ |
| ArgoCD | ✅ | ❌ | ✅ | ❌ | ✅ |
| ESO | ✅ | ✅ | ✅ | ✅ | ✅ |
| Backup | ✅ | ❌ | ✅ | ❌ | ✅ |
| **Compute** |
| GPU Support | ❌ | ✅ | Optional | ✅ | ✅ |
| Batch Jobs | ❌ | ✅ | Optional | ✅ | ✅ |
| **Security** |
| Customer KMS | ❌ | ❌ | ✅ | Partial | ❌ |
| PrivateLink | ❌ | ❌ | ✅ | ✅ | ❌ |
| Compliance | Basic | Basic | Full | Shared | Basic |

## Configuration

### Setting Deployment Type

In your configuration YAML:

```yaml
# Required
deployment_type: control_plane  # control_plane|data_plane|federated_byoc|hybrid_saas|full_stack
```

### Deployment Type Auto-Configuration

Based on the `deployment_type`, the following are automatically configured:

1. **Feature flags** (monitoring, backup, karpenter, etc.)
2. **Component selection** (which units to deploy)
3. **Cluster sizing** (instance types, node counts)
4. **Security settings** (KMS, PrivateLink, compliance)

### Override Defaults

You can override deployment type defaults in your config:

```yaml
deployment_type: control_plane

# Override default features
features:
  karpenter: true  # Enable even for control plane
  monitoring: false  # Disable monitoring

# Override cluster config
node_instance_types:
  - m5.2xlarge  # Use different instances
node_max_size: 10  # Increase max size
```

## Stack Files

Each deployment type has a dedicated stack file:

- `stacks/deployment-types/control-plane.stack.yaml`
- `stacks/deployment-types/data-plane.stack.yaml`
- `stacks/deployment-types/federated-byoc.stack.yaml`
- `stacks/deployment-types/hybrid-saas.stack.yaml`
- `stacks/aws/full.stack.yaml` (full stack)

## Deployment Commands

### Using Stack Selector (Recommended)

```bash
# Automatically select stack based on config
./scripts/select-stack.sh configs/your-environment.yaml

# Follow the output instructions
export TENANT_CONFIG_PATH="configs/your-environment.yaml"
terragrunt stack init --stack <selected-stack>
terragrunt stack plan --stack <selected-stack>
terragrunt stack apply --stack <selected-stack>
```

### Manual Stack Selection

```bash
# Set config path
export TENANT_CONFIG_PATH="configs/control-plane.yaml"

# Deploy control plane
terragrunt stack apply --stack stacks/deployment-types/control-plane.stack.yaml

# Deploy data plane
terragrunt stack apply --stack stacks/deployment-types/data-plane.stack.yaml
```

### GitHub Actions Workflow

```yaml
# In apiary repo
- name: Deploy Infrastructure
  uses: honeyhiveai/honeyhive-workflows/.github/workflows/terragrunt-stack-deploy.yml@main
  with:
    environment: prod-control-plane
    stack: control-plane  # Automatically uses right stack file
    action: apply
```

## Multi-Region Patterns

### Control Plane + Multiple Data Planes

```
┌─────────────────┐
│  Control Plane  │  us-west-2 (control-01)
│   (us-west-2)   │  - API, Dashboard
└────────┬────────┘  - ArgoCD, Monitoring
         │
    ┌────┴────┬──────────┬──────────┐
    │         │          │          │
┌───▼───┐ ┌──▼───┐ ┌────▼───┐ ┌────▼───┐
│ Data  │ │ Data │ │  Data  │ │  Data  │
│Plane 1│ │Plane2│ │Plane 3 │ │Plane 4 │
│us-e-1 │ │eu-w-1│ │ap-se-1 │ │us-w-2  │
└───────┘ └──────┘ └────────┘ └────────┘
compute-01 compute-02 compute-03 compute-04
```

### Federated Multi-Customer

```
┌──────────────────┐
│ HoneyHive Control│  Shared control plane
└────────┬─────────┘
         │
    ┌────┴────┬──────────┬──────────┐
    │         │          │          │
┌───▼───┐ ┌──▼───┐ ┌────▼───┐ ┌────▼───┐
│Cust A │ │Cust B│ │ Cust C │ │ Cust D │
│ BYOC  │ │ BYOC │ │  BYOC  │ │  BYOC  │
└───────┘ └──────┘ └────────┘ └────────┘
 AWS ACC   AWS ACC   AWS ACC    AWS ACC
 12345     67890     11111      22222
```

## Best Practices

### 1. Start Small

Begin with a single deployment type and expand:

```bash
# Start with control plane
deployment_type: control_plane

# Later add data planes
deployment_type: data_plane
```

### 2. Use Appropriate Sizing

Each deployment type has recommended sizing:

- **Control Plane**: 2-4 nodes, t3.xlarge
- **Data Plane**: 1-100 nodes, c6i instances
- **BYOC**: Customer preference
- **Hybrid**: Based on workload

### 3. Security Considerations

- **Control Plane**: Private endpoints, no public access
- **Data Plane**: Minimal permissions, no state
- **BYOC**: Customer KMS, PrivateLink only
- **Hybrid**: Encrypted tunnels, IAM roles

### 4. Cost Optimization

- **Control Plane**: Reserved instances
- **Data Plane**: Spot instances for compute
- **BYOC**: Customer pays infrastructure
- **Hybrid**: Split costs (control/data)

## Troubleshooting

### Issue: Wrong components deploying

Check deployment type in config:

```bash
yq eval '.deployment_type' configs/your-config.yaml
```

### Issue: Features not enabled

Check deployment type defaults:

```bash
grep -A 20 "deployment_type_name =" includes/deployment-types.hcl
```

### Issue: Stack not found

Ensure using correct stack file:

```bash
ls -la stacks/deployment-types/
```

## Migration Guide

### From Old Architecture

1. Choose appropriate deployment type
2. Create new config with `deployment_type` set
3. Use `-next` suffix units (avoid state conflicts)
4. Deploy with new stack
5. Migrate data if needed
6. Decommission old infrastructure

### Between Deployment Types

1. Deploy new type alongside existing
2. Migrate data/workloads
3. Update DNS/routing
4. Decommission old deployment

## Support

For questions about deployment types:

1. Check examples in `examples/configs/`
2. Review stack files in `stacks/deployment-types/`
3. See `includes/deployment-types.hcl` for defaults
4. Run `./scripts/select-stack.sh` for guidance

---

*This architecture enables true enterprise-scale, multi-tenant deployments with maximum flexibility.*
