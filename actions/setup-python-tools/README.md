# Setup Python Tools Action

This GitHub Action sets up Python and installs the required dependencies for HoneyHive workflow scripts.

## Purpose

Ensures that Python scripts in the workflows (like `select-stack.py`) have their required dependencies installed on GitHub Actions runners.

## Usage

### Basic Usage

```yaml
- name: Setup Python Tools
  uses: ./workflow-repo/actions/setup-python-tools
  with:
    python_version: '3.11'
    requirements_file: workflow-repo/scripts/requirements.txt
```

### From Another Repository

```yaml
- name: Setup Python Tools
  uses: honeyhiveai/honeyhive-workflows/actions/setup-python-tools@main
  with:
    python_version: '3.11'
```

### With Custom Requirements

```yaml
- name: Setup Python Tools
  uses: ./actions/setup-python-tools
  with:
    python_version: '3.10'
    requirements_file: path/to/my-requirements.txt
    cache_dependencies: 'false'
```

## Inputs

| Input | Description | Required | Default |
|-------|-------------|----------|---------|
| `python_version` | Python version to install | No | `3.11` |
| `requirements_file` | Path to requirements file | No | `scripts/requirements.txt` |
| `cache_dependencies` | Cache pip dependencies | No | `true` |

## Outputs

| Output | Description |
|--------|-------------|
| `python-version` | The installed Python version |
| `cache-hit` | Whether the cache was hit |

## What It Does

1. **Installs Python**: Sets up the specified Python version using `actions/setup-python`
2. **Caches Dependencies**: Caches pip packages to speed up subsequent runs
3. **Installs Dependencies**: Installs packages from requirements file or defaults (pyyaml, rich)
4. **Verifies Installation**: Checks that key packages are installed correctly
5. **Adds Scripts to PATH**: Makes Python scripts executable and adds them to PATH

## Default Dependencies

If no requirements file is found, the action installs:
- `pyyaml>=6.0` - For YAML configuration parsing
- `rich>=13.0` - For beautiful terminal output

## Example Workflow

```yaml
name: Deploy Infrastructure

on:
  workflow_dispatch:

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v4
        
      - name: Setup Python Tools
        uses: honeyhiveai/honeyhive-workflows/actions/setup-python-tools@main
        
      - name: Select Stack
        run: |
          ./scripts/select-stack.py configs/production.yaml
```

## Caching

The action caches pip packages based on the hash of the requirements file. This significantly speeds up subsequent runs by avoiding re-downloading packages.

Cache key format: `{os}-pip-{requirements_hash}`

## Error Handling

- If the requirements file is not found, the action falls back to installing core dependencies
- Installation failures are reported with clear error messages
- Verification step ensures packages are properly installed

## Performance

- First run: ~30-45 seconds (downloads and installs packages)
- Subsequent runs with cache: ~5-10 seconds (restores from cache)

## Troubleshooting

### Import Errors

If you get import errors after setup:
1. Check that the requirements file exists and is valid
2. Verify the Python version is compatible with your packages
3. Clear the cache if dependencies have changed

### Cache Issues

To force a cache refresh:
1. Change the requirements file (even adding a comment works)
2. Or set `cache_dependencies: 'false'`

### Path Issues  

The action automatically adds script directories to PATH:
- `workflow-repo/scripts/` (for honeyhive-workflows scripts)
- `scripts/` (for calling repository scripts)

Make sure your scripts have the correct shebang: `#!/usr/bin/env python3`
