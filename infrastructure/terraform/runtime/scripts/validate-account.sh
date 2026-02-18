#!/bin/bash
# ============================================================================
# AWS Account Validation Script
# ============================================================================
# This script validates that the current AWS credentials are for the expected
# account before running Terraform commands. This prevents accidental 
# deployments to the wrong AWS account.
#
# Usage:
#   ./scripts/validate-account.sh <environment>
#
# Example:
#   ./scripts/validate-account.sh dev
#   ./scripts/validate-account.sh production
# ============================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if environment argument is provided
if [ -z "$1" ]; then
  echo -e "${RED}❌ ERROR: Environment argument required${NC}"
  echo "Usage: $0 <environment>"
  echo "Example: $0 dev"
  exit 1
fi

ENVIRONMENT="$1"
LOCALS_FILE="locals.tf"

# Check if locals.tf exists
if [ ! -f "$LOCALS_FILE" ]; then
  echo -e "${RED}❌ ERROR: Configuration file not found: $LOCALS_FILE${NC}"
  exit 1
fi

# Extract expected account ID from locals.tf for the specific environment
# This looks for the account_ids map and extracts the value for the environment
EXPECTED_ACCOUNT_ID=$(awk -v env="$ENVIRONMENT" '
  /account_ids *= *{/,/}/ {
    if ($1 == env) {
      # Extract the account ID (handling both quoted and commented formats)
      if (match($0, /"([0-9]{12})"/)) {
        print substr($0, RSTART+1, RLENGTH-2)
        exit
      }
    }
  }
' "$LOCALS_FILE" | tr -d ' ')

# Check if account ID is set (not null or empty)
if [ -z "$EXPECTED_ACCOUNT_ID" ]; then
  echo -e "${YELLOW}⚠️  WARNING: No account ID validation configured for '$ENVIRONMENT' environment${NC}"
  echo "To enable validation, set the account ID in $LOCALS_FILE"
  echo ""
  echo "Example:"
  echo "  account_ids = {"
  echo "    $ENVIRONMENT = \"123456789012\"  # Your $ENVIRONMENT account"
  echo "  }"
  echo ""
  echo "Skipping account validation..."
  exit 0
fi

# Get current AWS account ID
echo "Checking AWS credentials..."
CURRENT_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text 2>&1)

# Check if AWS CLI command failed
if [ $? -ne 0 ]; then
  echo -e "${RED}❌ ERROR: Failed to get AWS account information${NC}"
  echo "Make sure you have valid AWS credentials configured."
  echo ""
  echo "Error: $CURRENT_ACCOUNT_ID"
  exit 1
fi

# Validate account ID matches
if [ "$CURRENT_ACCOUNT_ID" != "$EXPECTED_ACCOUNT_ID" ]; then
  echo ""
  echo -e "${RED}╔════════════════════════════════════════════════════════════════╗${NC}"
  echo -e "${RED}║                   ❌ ACCOUNT MISMATCH!                        ║${NC}"
  echo -e "${RED}╚════════════════════════════════════════════════════════════════╝${NC}"
  echo ""
  echo -e "${RED}Current AWS Account:${NC}  $CURRENT_ACCOUNT_ID"
  echo -e "${RED}Expected Account:${NC}     $EXPECTED_ACCOUNT_ID"
  echo -e "${RED}Environment:${NC}          $ENVIRONMENT"
  echo ""
  echo "You are attempting to deploy to the wrong AWS account!"
  echo "Please check your AWS credentials and try again."
  echo ""
  exit 1
fi

# Success
echo ""
echo -e "${GREEN}✅ Account validation passed!${NC}"
echo ""
echo "  Environment:    $ENVIRONMENT"
echo "  AWS Account:    $CURRENT_ACCOUNT_ID"
echo "  AWS Region:     $(aws configure get region 2>/dev/null || echo 'default')"
echo "  Identity:       $(aws sts get-caller-identity --query Arn --output text)"
echo ""
exit 0
