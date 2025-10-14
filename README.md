# Honeyhive Workflows

> **Federated catalog of reusable GitHub Actions workflows and Terragrunt overlays for BYOC deployments**

This repository provides the public/internal catalog for Honeyhive's federated infrastructure deployment model. It contains reusable GitHub Actions workflows for Terragrunt operations and cloud-specific Terragrunt overlays that enforce consistent patterns across tenant deployments.

## 🏗️ Architecture Overview

This catalog is part of a three-repository architecture:

1. **honeyhive-workflows** (this repo) - Reusable workflows and overlays
2. **honeyhive-terraform** - Terraform root modules only
3. **apiary** - Private tenant configurations and stacks

## 📁 Repository Structure

```
honeyhive-workflows/
├─ actions/                    # Composite GitHub Actions
│  ├─ setup-terragrunt/        # Install Terraform & Terragrunt
│  └─ git-auth-github-app/     # Configure git auth with GitHub App
├─ overlays/                   # Terragrunt overlays
│  ├─ aws/root.hcl            # AWS provider & state configuration
│  └─ azure/root.hcl          # Azure provider (stub)
├─ .github/workflows/          # Reusable workflows
│  ├─ rwf-tg-plan.yml         # Terragrunt plan workflow
│  ├─ rwf-tg-apply.yml        # Terragrunt apply workflow  
│  ├─ rwf-tg-destroy.yml      # Terragrunt destroy workflow
│  └─ rwf-tg-drift.yml        # Drift detection workflow
├─ examples/                   # Example configurations
│  ├─ tenant-caller-*.yml     # Sample caller workflows
│  ├─ tenant-terragrunt.hcl   # Sample Terragrunt config
│  └─ tenant.yaml             # Sample tenant configuration
└─ docs/                       # Documentation
   └─ WORKFLOWS.md            # Detailed workflow documentation
```

## 🚀 Quick Start

### For Tenant Onboarding

1. **Create your stack** in the apiary repository:
   ```
   apiary/{org}/{sregion}/
   ├─ tenant.yaml      # Your configuration
   └─ terragrunt.hcl   # Points to catalog overlay & Terraform module
   ```

2. **Set up caller workflows** in your apiary repository:
   - Copy examples from `examples/tenant-caller-*.yml`
   - Configure GitHub secrets (App ID, private key, AWS OIDC role)
   - Customize for your organization

3. **Configure authentication**:
   - GitHub App for private module access
   - AWS OIDC role for cloud resource provisioning

## 🔧 Composite Actions

### setup-terragrunt

Installs Terraform and Terragrunt with specified versions.

```yaml
- uses: honeyhiveai/honeyhive-workflows/actions/setup-terragrunt@v1
  with:
    terraform_version: '1.9.8'    # Optional, defaults to 1.9.8
    terragrunt_version: '0.66.9'  # Optional, defaults to 0.66.9
```

### git-auth-github-app

Configures git to use GitHub App token for HTTPS authentication.

```yaml
- uses: honeyhiveai/honeyhive-workflows/actions/git-auth-github-app@v1
  with:
    token: ${{ secrets.GH_APP_TOKEN }}
```

## 🔄 Reusable Workflows

All workflows follow a consistent contract:

### Common Inputs
- `stack_path` (required): Path to stack in caller repo
- `overlay_ref` (optional): Version of this catalog to use
- `tg_args` (optional): Additional Terragrunt arguments

### Common Secrets
- `GH_APP_ID`, `GH_APP_PRIVATE_KEY`: For GitHub App auth
- `GH_APP_TOKEN`: Pre-minted token (alternative)
- `AWS_OIDC_ROLE`: AWS role for authentication

### Workflow Details

| Workflow | Purpose | Key Features |
|----------|---------|--------------|
| `rwf-tg-plan.yml` | Generate Terragrunt plan | Format/validate/security checks, plan summary |
| `rwf-tg-apply.yml` | Apply infrastructure changes | Environment protection, apply logs |
| `rwf-tg-destroy.yml` | Destroy infrastructure | Confirmation required, state backup |
| `rwf-tg-drift.yml` | Detect configuration drift | Issue creation, webhook notifications |

## 📦 Overlays

### AWS Overlay (`overlays/aws/root.hcl`)

Provides:
- AWS provider configuration with default tags
- S3 backend state configuration
- Region validation
- Common locals from tenant.yaml

### Azure Overlay (`overlays/azure/root.hcl`)

Stub implementation for future Azure support.

## 🏷️ Tagging Strategy

All resources are tagged with:
- `Owner`: honeyhive
- `Organization`: From tenant config
- `Environment`: dev/test/stage/prod
- `Region`: AWS region
- `Deployment`: Unique deployment ID
- `Service`: Service being deployed
- `Layer`: substrate/hosting/application
- `ManagedBy`: Terraform
- `Repository`: Source repository URL

## 🔐 Security

### GitHub App Authentication

Required for accessing private Terraform modules:
- `GH_APP_ID`: GitHub App ID
- `GH_APP_PRIVATE_KEY`: Private key (base64 encoded)
- `GH_APP_INSTALLATION_TOKEN_SALT`: Optional salt

### AWS OIDC Authentication

Federated authentication without long-lived credentials:
- Deploy `HoneyhiveProvisioner` role in tenant account
- Trust central `HoneyhiveFederatedProvisioner` role
- Pass role ARN as `AWS_OIDC_ROLE` secret

## 📊 State Management

### Default State Configuration
- **Bucket**: `honeyhive-federated-{sregion}-state`
- **Key**: `{org}/{env}/{sregion}/{deployment}/{layer}/{service}/tfstate.json`
- **Region**: One bucket per region
- **Locking**: DynamoDB table
- **Encryption**: Enabled by default

### BYOC State Override

Tenants can override the state bucket in their `tenant.yaml`:
```yaml
state_bucket: my-custom-terraform-state-bucket
```

## 🔄 Versioning

This catalog follows semantic versioning:
- **Major**: Breaking changes to workflow contracts
- **Minor**: New features, backwards compatible
- **Patch**: Bug fixes

Pin to specific versions in your caller workflows:
```yaml
uses: honeyhiveai/honeyhive-workflows/.github/workflows/rwf-tg-plan.yml@v1.2.3
```

## 📈 Workflow Pipeline Order

Plan workflow execution order:
1. **Parallel**: Format check | Validate | Security scan
2. **Sequential**: Linter
3. **Sequential**: Terragrunt plan
4. **Output**: Job summary & artifact upload

## 🚦 Concurrency Control

Workflows use concurrency groups to prevent overlapping operations:
```yaml
concurrency:
  group: tg-${{ inputs.stack_path }}
  cancel-in-progress: false  # Don't cancel running applies
```

## 📝 Examples

See the `examples/` directory for:
- Complete tenant.yaml configuration
- Terragrunt.hcl with overlay inclusion
- Caller workflows for plan/apply/destroy/drift

## 🤝 Contributing

1. Create feature branch from `main`
2. Make changes and test thoroughly
3. Update documentation and examples
4. Submit PR with clear description
5. Tag new version after merge

## 📚 Additional Resources

- [Detailed Workflow Documentation](docs/WORKFLOWS.md)
- [Honeyhive Terraform Modules](https://github.com/honeyhiveai/honeyhive-terraform)
- [Terragrunt Documentation](https://terragrunt.gruntwork.io/)

## 🐛 Troubleshooting

### Common Issues

1. **Module authentication fails**
   - Verify GitHub App credentials
   - Check token generation in workflow

2. **State access denied**
   - Verify AWS OIDC role configuration
   - Check bucket permissions

3. **Overlay not found**
   - Ensure `overlay_ref` is specified
   - Check catalog checkout step

## 📄 License

[Internal Use Only - Honeyhive Proprietary]