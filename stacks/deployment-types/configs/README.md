# Deployment Type Configurations

This directory contains YAML configuration files that define different deployment types for HoneyHive infrastructure. Platform engineers can modify these files to customize deployment patterns without changing any code.

## Overview

Each YAML file in this directory defines a deployment type with its characteristics:

- **Components**: Which infrastructure layers to deploy
- **Features**: What features to enable/disable
- **Cluster Configuration**: Node types, sizes, scaling parameters
- **Network Configuration**: Subnet sizing, NAT strategy, VPC endpoints
- **Security Settings**: Encryption, compliance, audit controls

## Configuration Files

| File | Deployment Type | Description |
|------|----------------|-------------|
| `full_stack.yaml` | Complete Platform | All components and features enabled |
| `control_plane.yaml` | Management Services | API, dashboard, GitOps |
| `data_plane.yaml` | Compute Workloads | Processing and ML tasks |
| `federated_byoc.yaml` | Customer Cloud | Deploy in customer's AWS account |
| `hybrid_saas.yaml` | Split Architecture | Control in HoneyHive, data in customer |
| `edge.yaml` | Edge/IoT | Low-latency edge deployments (not yet implemented) |

## Configuration Structure

### Basic Structure

```yaml
name: deployment_type_name          # Unique identifier
description: Human readable description
stack_file: path/to/stack.yaml     # Terragrunt stack file to use
enabled: true                       # Set to false to disable

components:                        # Infrastructure layers to deploy
  - substrate
  - hosting
  - application

features:                          # Features to enable
  - monitoring
  - argocd
  - karpenter

disabled_features:                 # Explicitly disabled features
  - twingate
  - gpu_support
```

### Cluster Configuration

```yaml
cluster_config:
  node_instance_types:
    - t3.large
    - t3.xlarge
  min_nodes: 2
  max_nodes: 10
  desired_nodes: 3
  spot_enabled: true              # Enable spot instances
  spot_percentage: 80             # Percentage of spot vs on-demand
```

### Network Configuration  

```yaml
subnet_config:
  count: 3                        # Number of availability zones
  nat_strategy: single            # none, single, or per_az
  public_newbits: 8              # Subnet size calculation
  private_newbits: 4             # Subnet size calculation
```

### VPC Endpoints

```yaml
vpc_endpoints:
  gateway:                       # Gateway endpoints (free)
    - s3
    - dynamodb
  interface:                     # Interface endpoints (charged)
    - ecr.dkr
    - logs
    - ssm
```

### Security Configuration (BYOC)

```yaml
security:
  encryption: customer_managed
  compliance:
    - cloudtrail
    - guardduty
  standards:
    - cis-aws-foundations-benchmark
    - pci-dss
```

## Adding a New Deployment Type

1. Create a new YAML file: `my_deployment.yaml`
2. Define the required fields:

   ```yaml
   name: my_deployment
   description: My custom deployment type
   stack_file: stacks/deployment-types/my-deployment.stack.yaml
   components:
     - substrate
     - hosting
   features:
     - monitoring
   ```

3. Create the corresponding stack file referenced in `stack_file`
4. Test with: `./scripts/select-stack.py --list`

## Modifying Existing Types

Platform engineers can customize deployment types by editing the YAML files:

### Example: Change Node Types for Data Plane

Edit `data_plane.yaml`:

```yaml
cluster_config:
  node_instance_types:
    - c6i.4xlarge     # Changed from c6i.2xlarge
    - c6i.8xlarge     # Added larger instance
    - m6i.4xlarge     # Added memory-optimized
```

### Example: Add VPC Endpoints to Control Plane

Edit `control_plane.yaml`:

```yaml
vpc_endpoints:
  interface:
    - ecr.dkr
    - logs
    - rds            # Added RDS endpoint
    - lambda         # Added Lambda endpoint
```

### Example: Enable GPU Support

Edit `data_plane.yaml`:

```yaml
features:
  - karpenter
  - gpu_support      # Now enabled

cluster_config:
  node_instance_types:
    - g4dn.xlarge    # GPU instance
    - g4dn.2xlarge
```

## Testing Changes

After modifying a configuration:

1. Validate YAML syntax:

   ```bash
   python3 -c "import yaml; yaml.safe_load(open('my_deployment.yaml'))"
   ```

2. Test with the selector:

   ```bash
   ./scripts/select-stack.py --list
   ```

3. Test with a config file:

   ```bash
   ./scripts/select-stack.py configs/test-environment.yaml
   ```

## Best Practices

1. **Keep names consistent**: Use snake_case for deployment type names
2. **Document changes**: Update descriptions when modifying
3. **Test before deploying**: Always validate YAML syntax
4. **Version control**: Commit changes with clear messages
5. **Gradual changes**: Test in lower environments first

## Disabling a Deployment Type

To temporarily disable a deployment type without deleting:

```yaml
name: experimental_type
enabled: false        # This type won't be available
description: Experimental deployment (disabled)
```

## Environment-Specific Overrides

The configuration system supports overrides in the tenant config:

```yaml
# In your environment config (e.g., configs/prod.yaml)
deployment_type: control_plane

# Override defaults from control_plane.yaml
subnet_count: 3              # Use 3 AZs instead of 2
node_max_size: 8             # Allow more nodes
```

## Troubleshooting

### Configuration Not Loading

- Check YAML syntax: No tabs, proper indentation
- Verify file extension: `.yaml` or `.yml`
- Check `enabled` field is not `false`

### Stack File Not Found

- Verify `stack_file` path is correct
- Ensure the stack file exists in the repository
- Check relative path from repository root

### Features Not Working

- Some features require specific components
- Check dependencies between features
- Review disabled_features list

## Support

For questions or issues:

1. Check this README
2. Run `./scripts/select-stack.py --help`
3. Review example configurations
4. Check deployment type definitions in stack files
