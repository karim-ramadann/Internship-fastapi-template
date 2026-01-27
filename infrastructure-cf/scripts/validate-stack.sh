#!/bin/bash
# Validate a CloudFormation template
# Usage: ./validate-stack.sh <template-file> [environment]

set -e

TEMPLATE_FILE=${1?Error: Template file required}
ENVIRONMENT=${2:-""}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INFRA_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Validate template file exists
if [ ! -f "${INFRA_DIR}/${TEMPLATE_FILE}" ]; then
  echo "Error: Template file ${TEMPLATE_FILE} not found"
  exit 1
fi

echo "Validating CloudFormation template: ${TEMPLATE_FILE}"

# TODO: Implement actual CloudFormation template validation
# VALIDATION_OUTPUT=$(aws cloudformation validate-template \
#   --template-body file://"${INFRA_DIR}/${TEMPLATE_FILE}" 2>&1)

# if [ $? -eq 0 ]; then
#   echo "✓ Template is valid"
#   echo ""
#   echo "Template description:"
#   echo "$VALIDATION_OUTPUT" | jq -r '.Description // "No description"'
#   echo ""
#   echo "Parameters:"
#   echo "$VALIDATION_OUTPUT" | jq -r '.Parameters | keys[]' || echo "No parameters"
#   exit 0
# else
#   echo "✗ Template validation failed"
#   echo "$VALIDATION_OUTPUT"
#   exit 1
# fi

# Placeholder validation
echo "Placeholder: Template ${TEMPLATE_FILE} would be validated"
echo "Checking basic YAML syntax..."

# Basic YAML syntax check (if yq or python available)
if command -v python3 &> /dev/null; then
  python3 -c "import yaml; yaml.safe_load(open('${INFRA_DIR}/${TEMPLATE_FILE}'))" && echo "✓ Basic YAML syntax is valid"
elif command -v yq &> /dev/null; then
  yq eval '.' "${INFRA_DIR}/${TEMPLATE_FILE}" > /dev/null && echo "✓ Basic YAML syntax is valid"
else
  echo "⚠ Skipping YAML syntax check (python3 or yq not available)"
fi

echo ""
echo "Note: Full CloudFormation validation requires AWS CLI and will be implemented later"
