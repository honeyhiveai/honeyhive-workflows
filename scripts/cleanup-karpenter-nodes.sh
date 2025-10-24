#!/bin/bash
# Cleanup Karpenter-provisioned nodes before cluster destroy
# Prevents orphaned EC2 instances and security group deletion issues

set -euo pipefail

CLUSTER_NAME="${1:-}"
REGION="${2:-us-west-2}"

if [ -z "$CLUSTER_NAME" ]; then
  echo "Usage: $0 <cluster-name> [region]"
  exit 1
fi

echo "Cleaning up Karpenter-provisioned nodes for cluster: $CLUSTER_NAME"

# Find all EC2 instances with karpenter.sh/cluster tag
INSTANCE_IDS=$(aws ec2 describe-instances \
  --region "$REGION" \
  --filters \
    "Name=tag:karpenter.sh/cluster,Values=$CLUSTER_NAME" \
    "Name=instance-state-name,Values=running,pending,stopping,stopped" \
  --query 'Reservations[*].Instances[*].InstanceId' \
  --output text)

if [ -z "$INSTANCE_IDS" ]; then
  echo "No Karpenter nodes found - already clean!"
  exit 0
fi

echo "Found Karpenter nodes: $INSTANCE_IDS"
echo "Terminating..."

aws ec2 terminate-instances \
  --region "$REGION" \
  --instance-ids $INSTANCE_IDS

echo "⏳ Waiting for instances to terminate..."
aws ec2 wait instance-terminated \
  --region "$REGION" \
  --instance-ids $INSTANCE_IDS

echo "All Karpenter nodes terminated successfully!"

