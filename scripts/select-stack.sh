#!/bin/bash
set -euo pipefail

# Stack selector based on deployment type
# This script determines which stack to use based on the deployment_type in the config

CONFIG_FILE="${1:-}"
if [ -z "$CONFIG_FILE" ] || [ ! -f "$CONFIG_FILE" ]; then
    echo "Error: Please provide a valid configuration file"
    echo "Usage: $0 <config.yaml>"
    exit 1
fi

# Extract deployment type from config
DEPLOYMENT_TYPE=$(yq eval '.deployment_type' "$CONFIG_FILE")

if [ -z "$DEPLOYMENT_TYPE" ] || [ "$DEPLOYMENT_TYPE" == "null" ]; then
    echo "Error: deployment_type not found in configuration"
    exit 1
fi

# Map deployment type to stack file
case "$DEPLOYMENT_TYPE" in
    full_stack)
        STACK_FILE="stacks/aws/full.stack.yaml"
        echo "Full Stack deployment - all components"
        ;;
    control_plane)
        STACK_FILE="stacks/deployment-types/control-plane.stack.yaml"
        echo "Control Plane deployment - API and management"
        ;;
    data_plane)
        STACK_FILE="stacks/deployment-types/data-plane.stack.yaml"
        echo "Data Plane deployment - compute workloads"
        ;;
    federated_byoc)
        STACK_FILE="stacks/deployment-types/federated-byoc.stack.yaml"
        echo "Federated BYOC deployment - customer cloud"
        ;;
    hybrid_saas)
        STACK_FILE="stacks/deployment-types/hybrid-saas.stack.yaml"
        echo "Hybrid SaaS deployment - split control/data"
        ;;
    edge)
        echo "Error: Edge deployment not yet implemented"
        exit 1
        ;;
    *)
        echo "Error: Unknown deployment type: $DEPLOYMENT_TYPE"
        echo "Valid types: full_stack, control_plane, data_plane, federated_byoc, hybrid_saas"
        exit 1
        ;;
esac

# Output the stack file path
echo "Selected stack: $STACK_FILE"
echo ""
echo "To deploy this stack:"
echo "  export TENANT_CONFIG_PATH=\"$CONFIG_FILE\""
echo "  terragrunt stack init --stack $STACK_FILE"
echo "  terragrunt stack plan --stack $STACK_FILE"
echo "  terragrunt stack apply --stack $STACK_FILE"

# Export for use in scripts
echo ""
echo "Export for automation:"
echo "export SELECTED_STACK=\"$STACK_FILE\""
