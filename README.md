# HoneyHive Workflows

Reusable GitHub Actions workflows for HoneyHive infrastructure deployments.

## Overview

This repository contains centralized, versioned, reusable workflows that can be called from deployment repositories (like `apiary`) to manage infrastructure using Terragrunt and the `honeyhive-terraform` repository.

## Workflows

### Terragrunt Deploy

**File**: `.github/workflows/terragrunt-deploy.yml`

Reusable workflow for deploying infrastructure via Terragrunt.

**Usage**:

```yaml
jobs:
  deploy:
    uses: honeyhiveai/honeyhive-workflows/.github/workflows/terragrunt-deploy.yml@v1.0.0
    with:
      environment: production-usw2
      layer: all
      action: plan
      terraform_ref: v1.0.0
    secrets:
      GH_APP_PRIVATE_KEY: ${{ secrets.GH_APP_PRIVATE_KEY }}
      TWINGATE_API_TOKEN: ${{ secrets.TWINGATE_API_TOKEN }}
      SLACK_TOKEN: ${{ secrets.SLACK_TOKEN }}
```

**Inputs**:
- `environment` - Environment config name (e.g., production-usw2)
- `layer` - Layer to deploy (all, substrate, hosting, application)
- `action` - Terraform action (plan, apply, destroy)
- `terraform_repo` - Terraform repo (default: honeyhiveai/honeyhive-terraform)
- `terraform_ref` - Git ref to use (tag/branch/SHA)
- `config_path` - Path to config files (default: configs)
- `terragrunt_version` - Terragrunt version (default: 0.55.0)
- `terraform_version` - Terraform version (default: 1.9.0)
- `aws_region` - AWS region (default: us-west-2)

**Inputs** (from calling workflow):
- Can pass `aws_oidc_role` and `gh_app_id` as inputs
- Or use repository variables: `vars.AWS_OIDC_ROLE` and `vars.GH_APP_ID`

**Secrets**:
- `GH_APP_PRIVATE_KEY` - GitHub App private key in PEM format (required)
- `TWINGATE_API_TOKEN` - Twingate API token (optional)
- `SLACK_TOKEN` - Slack token (optional)

**Variables** (from calling repository):
- `AWS_OIDC_ROLE` - AWS IAM role ARN in orchestration account
  - Example: `arn:aws:iam::839515361289:role/HoneyhiveFederatedProvisioner`
  - Kept as variable (not secret) for troubleshooting visibility
- `GH_APP_ID` - GitHub App ID
  - Example: `2088377`
  - Kept as variable for quick identification during incidents

**Note**: AWS account ID is extracted from the YAML configuration file. Each environment config specifies its target account.

## Versioning

This repository uses semantic versioning with automated releases.

### Pull Request Process

1. Create a branch
2. Make changes
3. Open a PR with title including version tag:
   - `#major` - Breaking changes to workflow interfaces
   - `#minor` - New workflows or backward-compatible features
   - `#patch` - Bug fixes
   - `#none` - Documentation only

4. After merge, version tag and release are created automatically

### Referencing Workflows

Always pin to specific versions in production:

```yaml
# ✅ Good - pinned to version
uses: honeyhiveai/honeyhive-workflows/.github/workflows/terragrunt-deploy.yml@v1.0.0

# ⚠️ Caution - uses latest from main
uses: honeyhiveai/honeyhive-workflows/.github/workflows/terragrunt-deploy.yml@main
```

## Repository Structure

```
.
├── .github/workflows/
│   ├── pull_request.yml          # PR validation
│   ├── tag_and_release.yml       # Automated versioning
│   └── terragrunt-deploy.yml     # Reusable deployment workflow
└── README.md
```

## Contributing

### Adding a New Workflow

1. Create workflow file in `.github/workflows/`
2. Use `workflow_call` trigger for reusable workflows
3. Document all inputs and secrets
4. Test in a deployment repo (like apiary)
5. Open PR with `#minor` tag

### Modifying Existing Workflows

1. For breaking changes, use `#major` tag
2. For backward-compatible changes, use `#minor` tag
3. For bug fixes, use `#patch` tag
4. Update README with changes

## Best Practices

### For Workflow Authors

- ✅ Use clear input/secret names
- ✅ Provide sensible defaults
- ✅ Document all parameters
- ✅ Add validation steps
- ✅ Include summary outputs
- ✅ Handle errors gracefully

### For Workflow Consumers

- ✅ Always pin to specific versions
- ✅ Use GitHub environments for approvals
- ✅ Store secrets in GitHub Secrets
- ✅ Test in non-prod first
- ✅ Monitor workflow runs

## Related Repositories

- [honeyhive-terraform](https://github.com/honeyhiveai/honeyhive-terraform) - Infrastructure as code
- [apiary](https://github.com/honeyhiveai/apiary) - Internal deployments (private)

## Support

- **Issues**: https://github.com/honeyhiveai/honeyhive-workflows/issues
- **Discussions**: https://github.com/honeyhiveai/honeyhive-workflows/discussions

## License

Proprietary - HoneyHive, Inc.

