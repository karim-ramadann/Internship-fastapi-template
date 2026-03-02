#!/bin/bash
# Check the status of a CloudFormation stack
# Usage: ./stack-status.sh <stack-name> <environment> [--outputs]

set -e

STACK_NAME=${1?Error: Stack name required}
ENVIRONMENT=${2?Error: Environment required (dev/staging/prod)}
SHOW_OUTPUTS=${3:-""}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Full stack name with environment prefix
FULL_STACK_NAME="${ENVIRONMENT}-${STACK_NAME}"

# Check if stack exists
if ! aws cloudformation describe-stacks --stack-name "${FULL_STACK_NAME}" >/dev/null 2>&1; then
  echo "Stack ${FULL_STACK_NAME} does not exist"
  exit 1
fi

echo "Stack: ${FULL_STACK_NAME}"
echo "=========================================="

# TODO: Get and display stack status
# STACK_INFO=$(aws cloudformation describe-stacks --stack-name "${FULL_STACK_NAME}")
#
# echo "Status: $(echo "$STACK_INFO" | jq -r '.Stacks[0].StackStatus')"
# echo "Created: $(echo "$STACK_INFO" | jq -r '.Stacks[0].CreationTime')"
# echo "Last Updated: $(echo "$STACK_INFO" | jq -r '.Stacks[0].LastUpdatedTime // "Never"')"
#
# if [ "${SHOW_OUTPUTS}" = "--outputs" ]; then
#   echo ""
#   echo "Outputs:"
#   echo "$STACK_INFO" | jq -r '.Stacks[0].Outputs[]? | "  \(.OutputKey): \(.OutputValue)"' || echo "  No outputs"
# fi

# Placeholder status check
echo "Placeholder: Would show status for stack ${FULL_STACK_NAME}"
echo ""
echo "To get actual status, run:"
echo "  aws cloudformation describe-stacks --stack-name ${FULL_STACK_NAME}"
echo ""
if [ "${SHOW_OUTPUTS}" = "--outputs" ]; then
  echo "To get outputs, run:"
  echo "  aws cloudformation describe-stacks --stack-name ${FULL_STACK_NAME} --query 'Stacks[0].Outputs' --output table"
fi
