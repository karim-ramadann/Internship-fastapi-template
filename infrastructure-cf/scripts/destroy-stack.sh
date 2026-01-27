#!/bin/bash
# Safely destroy a CloudFormation stack
# Usage: ./destroy-stack.sh <stack-name> <environment> [--force]

set -e

STACK_NAME=${1?Error: Stack name required}
ENVIRONMENT=${2?Error: Environment required (dev/staging/prod)}
FORCE=${3:-""}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Full stack name with environment prefix
FULL_STACK_NAME="${ENVIRONMENT}-${STACK_NAME}"

# Check if stack exists
if ! aws cloudformation describe-stacks --stack-name "${FULL_STACK_NAME}" >/dev/null 2>&1; then
  echo "Stack ${FULL_STACK_NAME} does not exist"
  exit 0
fi

# Safety check for production
if [ "${ENVIRONMENT}" = "prod" ] && [ "${FORCE}" != "--force" ]; then
  echo "ERROR: Cannot destroy production stack without --force flag"
  echo "This is a safety measure to prevent accidental deletion"
  exit 1
fi

# Confirmation prompt
if [ "${FORCE}" != "--force" ]; then
  echo "WARNING: This will destroy stack: ${FULL_STACK_NAME}"
  echo "This action cannot be undone!"
  read -p "Are you sure you want to continue? (yes/no): " CONFIRM
  
  if [ "${CONFIRM}" != "yes" ]; then
    echo "Destruction cancelled"
    exit 0
  fi
fi

echo "Destroying stack: ${FULL_STACK_NAME}"

# TODO: Implement actual stack deletion
# aws cloudformation delete-stack --stack-name "${FULL_STACK_NAME}"
# echo "Stack deletion initiated. Waiting for completion..."
# aws cloudformation wait stack-delete-complete --stack-name "${FULL_STACK_NAME}"
# echo "Stack ${FULL_STACK_NAME} deleted successfully"

echo "Placeholder: Would delete stack ${FULL_STACK_NAME}"
echo "Note: Stack dependencies should be destroyed in reverse order"
echo "Recommended order: 06-monitoring, 05-async, 04-compute, 03-storage, 02-database, 01-network"
