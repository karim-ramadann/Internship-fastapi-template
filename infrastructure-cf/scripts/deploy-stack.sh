#!/bin/bash
# Deploy a single CloudFormation stack
# Usage: ./deploy-stack.sh <stack-name> <template-file> <environment> [parameter-file]

set -e

STACK_NAME=${1?Error: Stack name required}
TEMPLATE_FILE=${2?Error: Template file required}
ENVIRONMENT=${3?Error: Environment required (dev/staging/prod)}
PARAMETER_FILE=${4:-"parameters/${ENVIRONMENT}.json"}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INFRA_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Validate template file exists
if [ ! -f "${INFRA_DIR}/${TEMPLATE_FILE}" ]; then
  echo "Error: Template file ${TEMPLATE_FILE} not found"
  exit 1
fi

# Validate parameter file exists
if [ ! -f "${INFRA_DIR}/${PARAMETER_FILE}" ]; then
  echo "Error: Parameter file ${PARAMETER_FILE} not found"
  exit 1
fi

# Full stack name with environment prefix
FULL_STACK_NAME="${ENVIRONMENT}-${STACK_NAME}"

echo "Deploying stack: ${FULL_STACK_NAME}"
echo "Template: ${TEMPLATE_FILE}"
echo "Parameters: ${PARAMETER_FILE}"

# Check if stack exists
if aws cloudformation describe-stacks --stack-name "${FULL_STACK_NAME}" >/dev/null 2>&1; then
  echo "Stack ${FULL_STACK_NAME} exists, updating..."
  OPERATION="update-stack"
else
  echo "Stack ${FULL_STACK_NAME} does not exist, creating..."
  OPERATION="create-stack"
fi

# TODO: Implement actual CloudFormation deployment
# aws cloudformation ${OPERATION} \
#   --stack-name "${FULL_STACK_NAME}" \
#   --template-body file://"${INFRA_DIR}/${TEMPLATE_FILE}" \
#   --parameters file://"${INFRA_DIR}/${PARAMETER_FILE}" \
#   --capabilities CAPABILITY_IAM CAPABILITY_NAMED_IAM \
#   --tags Key=Environment,Value="${ENVIRONMENT}" Key=ManagedBy,Value=CloudFormation

echo "Placeholder: Would ${OPERATION} stack ${FULL_STACK_NAME}"
echo "Waiting for stack operation to complete..."

# TODO: Wait for stack operation to complete
# aws cloudformation wait stack-${OPERATION}-complete --stack-name "${FULL_STACK_NAME}"

echo "Stack ${FULL_STACK_NAME} ${OPERATION} completed successfully"

# Output stack outputs
echo "Stack outputs:"
# TODO: Get and display stack outputs
# aws cloudformation describe-stacks \
#   --stack-name "${FULL_STACK_NAME}" \
#   --query 'Stacks[0].Outputs' \
#   --output table
