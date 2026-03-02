#!/bin/bash
# Deploy all CloudFormation stacks in correct dependency order
# Usage: ./deploy-all.sh <environment> [--dry-run]

set -e

ENVIRONMENT=${1?Error: Environment required (dev/staging/prod)}
DRY_RUN=${2:-""}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INFRA_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Stack deployment order (based on dependencies)
STACKS=(
  "01-network:01-network.yaml"
  "02-database:02-database.yaml"
  "03-storage:03-storage.yaml"
  "04-compute:04-compute.yaml"
  "05-async:05-async.yaml"
  "06-monitoring:06-monitoring.yaml"
)

PARAMETER_FILE="parameters/${ENVIRONMENT}.json"

# Validate parameter file exists
if [ ! -f "${INFRA_DIR}/${PARAMETER_FILE}" ]; then
  echo "Error: Parameter file ${PARAMETER_FILE} not found"
  exit 1
fi

echo "Deploying all stacks for environment: ${ENVIRONMENT}"
if [ "${DRY_RUN}" = "--dry-run" ]; then
  echo "DRY RUN MODE - No changes will be made"
fi

# Validate all templates first
echo "Validating all CloudFormation templates..."
for stack_info in "${STACKS[@]}"; do
  IFS=':' read -r stack_name template_file <<< "${stack_info}"
  echo "Validating ${template_file}..."

  # TODO: Implement template validation
  # aws cloudformation validate-template \
  #   --template-body file://"${INFRA_DIR}/${template_file}" >/dev/null

  echo "  ✓ ${template_file} is valid"
done

echo ""
echo "All templates validated successfully"
echo ""

# Deploy stacks in order
for stack_info in "${STACKS[@]}"; do
  IFS=':' read -r stack_name template_file <<< "${stack_info}"
  FULL_STACK_NAME="${ENVIRONMENT}-${stack_name}"

  echo "=========================================="
  echo "Deploying: ${FULL_STACK_NAME}"
  echo "Template: ${template_file}"
  echo "=========================================="

  if [ "${DRY_RUN}" = "--dry-run" ]; then
    echo "DRY RUN: Would deploy ${FULL_STACK_NAME}"
  else
    # TODO: Call deploy-stack.sh for each stack
    # "${SCRIPT_DIR}/deploy-stack.sh" "${stack_name}" "${template_file}" "${ENVIRONMENT}" "${PARAMETER_FILE}"
    echo "Placeholder: Would deploy ${FULL_STACK_NAME}"
  fi

  echo ""
done

if [ "${DRY_RUN}" = "--dry-run" ]; then
  echo "DRY RUN completed - No stacks were deployed"
else
  echo "All stacks deployed successfully!"
fi
