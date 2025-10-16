#!/bin/bash
set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "================================================"
echo "    Terragrunt Stack Structure Validation"
echo "================================================"
echo ""

# Check directory structure
echo "📁 Checking directory structure..."

REQUIRED_DIRS=(
  "stacks/aws"
  "units/substrate"
  "units/hosting"
  "units/application"
  "includes"
)

for dir in "${REQUIRED_DIRS[@]}"; do
  if [ -d "$dir" ]; then
    echo -e "${GREEN}✓${NC} $dir exists"
  else
    echo -e "${RED}✗${NC} $dir missing"
    exit 1
  fi
done

echo ""
echo "📄 Checking stack definitions..."

STACK_FILES=(
  "stacks/aws/substrate.stack.yaml"
  "stacks/aws/hosting.stack.yaml"
  "stacks/aws/application.stack.yaml"
  "stacks/aws/full.stack.yaml"
)

for file in "${STACK_FILES[@]}"; do
  if [ -f "$file" ]; then
    echo -e "${GREEN}✓${NC} $file exists"
    # Validate YAML syntax
    if command -v python3 &> /dev/null; then
      if python3 -c "import yaml; yaml.safe_load(open('$file'))" > /dev/null 2>&1; then
        echo -e "  ${GREEN}✓${NC} Valid YAML syntax"
      else
        echo -e "  ${RED}✗${NC} Invalid YAML syntax"
        exit 1
      fi
    fi
  else
    echo -e "${RED}✗${NC} $file missing"
    exit 1
  fi
done

echo ""
echo "🔧 Checking shared includes..."

INCLUDE_FILES=(
  "includes/tenant-config.hcl"
  "includes/remote-state.hcl"
  "includes/aws-provider.hcl"
)

for file in "${INCLUDE_FILES[@]}"; do
  if [ -f "$file" ]; then
    echo -e "${GREEN}✓${NC} $file exists"
  else
    echo -e "${RED}✗${NC} $file missing"
    exit 1
  fi
done

echo ""
echo "📦 Checking unit configurations..."

# Find all units
UNITS=$(find units -name "terragrunt.hcl" -type f | sort)

if [ -z "$UNITS" ]; then
  echo -e "${RED}✗${NC} No units found!"
  exit 1
fi

for unit in $UNITS; do
  echo -e "${GREEN}✓${NC} $unit"
  
  # Check for required includes
  if grep -q 'include "tenant_config"' "$unit"; then
    echo -e "  ${GREEN}✓${NC} Has tenant_config include"
  else
    echo -e "  ${RED}✗${NC} Missing tenant_config include"
  fi
  
  if grep -q 'include "remote_state"' "$unit"; then
    echo -e "  ${GREEN}✓${NC} Has remote_state include"
  else
    echo -e "  ${RED}✗${NC} Missing remote_state include"
  fi
  
  if grep -q 'include "aws_provider"' "$unit"; then
    echo -e "  ${GREEN}✓${NC} Has aws_provider include"
  else
    echo -e "  ${RED}✗${NC} Missing aws_provider include"
  fi
  
  # Check for terraform source
  if grep -q 'terraform {' "$unit"; then
    echo -e "  ${GREEN}✓${NC} Has terraform source block"
  else
    echo -e "  ${RED}✗${NC} Missing terraform source block"
  fi
done

echo ""
echo "🔍 Checking for old patterns..."

# Check for old graph references
if find . -name "*.hcl" -o -name "*.yaml" | xargs grep -l "graphs/aws/full" 2>/dev/null; then
  echo -e "${YELLOW}⚠${NC} Found references to old graphs structure - please update"
fi

# Check for old run-all commands
if find . -name "*.yml" -o -name "*.yaml" | xargs grep -l "terragrunt run-all" 2>/dev/null | grep -v validate-stacks.sh; then
  echo -e "${YELLOW}⚠${NC} Found old 'terragrunt run-all' commands - should use 'terragrunt stack' instead"
fi

echo ""
echo "🎯 Validation Summary"
echo "===================="

# Check if we're ready for testing
if [ -f "stacks/aws/substrate.stack.yaml" ] && \
   [ -d "units/substrate/vpc-next" ] && \
   [ -d "units/substrate/dns-next" ] && \
   [ -f "includes/tenant-config.hcl" ]; then
  echo -e "${GREEN}✅ Structure is ready for substrate stack testing!${NC}"
  echo ""
  echo "Next steps:"
  echo "1. Set TENANT_CONFIG_PATH to your config file"
  echo "2. Run: terragrunt stack init --stack stacks/aws/substrate.stack.yaml"
  echo "3. Run: terragrunt stack plan --stack stacks/aws/substrate.stack.yaml"
else
  echo -e "${RED}❌ Structure is not complete${NC}"
  exit 1
fi
