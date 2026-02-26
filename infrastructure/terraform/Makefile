.PHONY: help init-dev init-staging init-production plan-dev plan-staging plan-production apply-dev apply-staging apply-production destroy-dev destroy-staging destroy-production fmt fmt-check init-ci validate tflint docs docs-modules docs-runtime clean trivy trivy-runtime trivy-modules trivy-all trivy-ci lint-ci

# Default environment
ENV ?= dev

# Color output
BLUE := \033[0;34m
GREEN := \033[0;32m
YELLOW := \033[0;33m
RED := \033[0;31m
NC := \033[0m # No Color

# Default target
help:
	@echo "$(BLUE)Runtime Infrastructure Terraform Makefile$(NC)"
	@echo ""
	@echo "$(GREEN)Available targets:$(NC)"
	@echo ""
	@echo "$(YELLOW)Environment-specific commands:$(NC)"
	@echo "  init-dev          - Initialize Terraform for dev environment"
	@echo "  init-staging      - Initialize Terraform for staging environment"
	@echo "  init-production   - Initialize Terraform for production environment"
	@echo ""
	@echo "  plan-dev          - Run terraform plan for dev"
	@echo "  plan-staging      - Run terraform plan for staging"
	@echo "  plan-production   - Run terraform plan for production"
	@echo ""
	@echo "  apply-dev         - Run terraform apply for dev"
	@echo "  apply-staging     - Run terraform apply for staging"
	@echo "  apply-production  - Run terraform apply for production"
	@echo ""
	@echo "  destroy-dev       - Run terraform destroy for dev"
	@echo "  destroy-staging   - Run terraform destroy for staging"
	@echo "  destroy-production- Run terraform destroy for production"
	@echo ""
	@echo "$(YELLOW)General commands:$(NC)"
	@echo "  fmt               - Format all Terraform files (runtime + modules)"
	@echo "  fmt-check         - Check formatting only, exit 1 if not formatted (CI)"
	@echo "  init-ci           - Init runtime with -backend=false (CI)"
	@echo "  validate          - Validate runtime Terraform configuration"
	@echo "  tflint            - Run tflint (init + recursive scan)"
	@echo "  lint-ci           - Run all CI lint targets: fmt-check, init-ci, validate, tflint, trivy-ci"
	@echo "  docs              - Generate documentation for runtime and all modules"
	@echo "  docs-modules      - Generate documentation for modules only"
	@echo "  docs-runtime      - Generate documentation for runtime only"
	@echo "  clean             - Clean Terraform cache files from runtime"
	@echo ""
	@echo "$(YELLOW)Linting:$(NC)"
	@echo "  tflint             - Lint runtime Terraform files (recommended)"
	@echo "  tflint-runtime     - Lint runtime directory only"
	@echo "  tflint-modules     - Lint all modules"
	@echo "  tflint-all         - Lint both runtime and modules"
	@echo ""
	@echo "$(YELLOW)Security scanning:$(NC)"
	@echo "  trivy             - Scan runtime for security issues (recommended)"
	@echo "  trivy-runtime     - Scan runtime directory only"
	@echo "  trivy-modules     - Scan modules directory only"
	@echo "  trivy-all         - Scan both runtime and modules with detailed output"
	@echo ""
	@echo "$(YELLOW)Examples:$(NC)"
	@echo "  make init-dev                    # Initialize dev environment"
	@echo "  make plan-dev                    # Plan dev deployment"
	@echo "  make apply-staging               # Apply staging changes"
	@echo "  make fmt                         # Format all .tf files"
	@echo "  make trivy                       # Security scan runtime"

# ============================================================================
# Development Environment
# ============================================================================

init-dev:
	@echo "$(BLUE)Initializing Terraform for development environment...$(NC)"
	cd runtime && terraform init -backend-config=environments/dev/backend.hcl

plan-dev:
	@echo "$(BLUE)Planning Terraform changes for development environment...$(NC)"
	cd runtime && terraform plan -var-file=environments/dev/terraform.tfvars

apply-dev:
	@echo "$(BLUE)Applying Terraform changes for development environment...$(NC)"
	cd runtime && terraform apply -var-file=environments/dev/terraform.tfvars

destroy-dev:
	@echo "$(RED)Destroying development environment...$(NC)"
	@echo "$(YELLOW)WARNING: This will destroy all resources in dev!$(NC)"
	cd runtime && terraform destroy -var-file=environments/dev/terraform.tfvars

# ============================================================================
# Staging Environment
# ============================================================================

init-staging:
	@echo "$(BLUE)Initializing Terraform for staging environment...$(NC)"
	cd runtime && terraform init -backend-config=environments/staging/backend.hcl

plan-staging:
	@echo "$(BLUE)Planning Terraform changes for staging environment...$(NC)"
	cd runtime && terraform plan -var-file=environments/staging/terraform.tfvars

apply-staging:
	@echo "$(BLUE)Applying Terraform changes for staging environment...$(NC)"
	cd runtime && terraform apply -var-file=environments/staging/terraform.tfvars

destroy-staging:
	@echo "$(RED)Destroying staging environment...$(NC)"
	@echo "$(YELLOW)WARNING: This will destroy all resources in staging!$(NC)"
	cd runtime && terraform destroy -var-file=environments/staging/terraform.tfvars

# ============================================================================
# Production Environment
# ============================================================================

init-production:
	@echo "$(BLUE)Initializing Terraform for production environment...$(NC)"
	cd runtime && terraform init -backend-config=environments/production/backend.hcl

plan-production:
	@echo "$(BLUE)Planning Terraform changes for production environment...$(NC)"
	cd runtime && terraform plan -var-file=environments/production/terraform.tfvars

apply-production:
	@echo "$(RED)Applying Terraform changes for production environment...$(NC)"
	@echo "$(YELLOW)WARNING: This will modify production resources!$(NC)"
	@read -p "Are you sure? [y/N] " -n 1 -r; \
	echo; \
	if [[ $$REPLY =~ ^[Yy]$$ ]]; then \
		cd runtime && terraform apply -var-file=environments/production/terraform.tfvars; \
	else \
		echo "$(YELLOW)Production apply cancelled.$(NC)"; \
	fi

destroy-production:
	@echo "$(RED)Destroying production environment...$(NC)"
	@echo "$(RED)DANGER: This will destroy all production resources!$(NC)"
	@read -p "Type 'destroy-production' to confirm: " confirm; \
	if [ "$$confirm" = "destroy-production" ]; then \
		cd runtime && terraform destroy -var-file=environments/production/terraform.tfvars; \
	else \
		echo "$(YELLOW)Production destroy cancelled.$(NC)"; \
	fi

# ============================================================================
# General Commands
# ============================================================================

# Format Terraform files (runtime + modules)
fmt:
	@echo "$(BLUE)Formatting Terraform files...$(NC)"
	@echo "Formatting runtime..."
	@terraform fmt -recursive runtime/
	@echo "Formatting modules..."
	@terraform fmt -recursive modules/
	@echo "$(GREEN)Formatting complete!$(NC)"

# Check formatting only (CI); exit 1 if not formatted
fmt-check:
	@echo "$(BLUE)Checking Terraform formatting...$(NC)"
	@terraform fmt -check -recursive runtime/
	@terraform fmt -check -recursive modules/
	@echo "$(GREEN)Formatting check passed!$(NC)"

# Init without backend (CI only)
init-ci:
	@echo "$(BLUE)Initializing Terraform for CI (no backend)...$(NC)"
	cd runtime && terraform init -backend=false
	@echo "$(GREEN)Init complete!$(NC)"

# Validate configuration (runtime only)
validate:
	@echo "$(BLUE)Validating runtime Terraform configuration...$(NC)"
	cd runtime && terraform validate

# TFLint (init plugins + recursive scan)
tflint:
	@echo "$(BLUE)Running TFLint...$(NC)"
	@if command -v tflint >/dev/null 2>&1; then \
		tflint --init && tflint --recursive; \
	else \
		echo "$(RED)tflint is not installed.$(NC)"; \
		exit 1; \
	fi
	@echo "$(GREEN)TFLint complete!$(NC)"

# Generate documentation using terraform-docs
docs: docs-runtime docs-modules
	@echo "$(GREEN)Documentation generation complete!$(NC)"

docs-runtime:
	@echo "$(BLUE)Generating runtime documentation...$(NC)"
	@if command -v terraform-docs >/dev/null 2>&1; then \
		cd runtime && terraform-docs --config .terraform-docs.yml .; \
		echo "$(GREEN)Runtime documentation generated!$(NC)"; \
	else \
		echo "$(RED)terraform-docs is not installed.$(NC)"; \
		echo "Install it from: https://terraform-docs.io/"; \
		exit 1; \
	fi

docs-modules:
	@echo "$(BLUE)Generating module documentation...$(NC)"
	@if command -v terraform-docs >/dev/null 2>&1; then \
		for dir in modules/*/; do \
			if [ -f "$$dir/main.tf" ]; then \
				echo "  Generating docs for $$dir"; \
				terraform-docs --config modules/.terraform-docs.yml "$$dir"; \
			fi \
		done; \
		echo "$(GREEN)Module documentation generated!$(NC)"; \
	else \
		echo "$(RED)terraform-docs is not installed.$(NC)"; \
		echo "Install it from: https://terraform-docs.io/"; \
		exit 1; \
	fi

# Clean Terraform cache (runtime only)
clean:
	@echo "$(BLUE)Cleaning Terraform cache from runtime...$(NC)"
	cd runtime && rm -rf .terraform
	cd runtime && rm -f .terraform.lock.hcl
	cd runtime && rm -f terraform.tfstate
	cd runtime && rm -f terraform.tfstate.backup
	cd runtime && rm -f crash.log
	@echo "$(GREEN)Clean complete!$(NC)"

# ============================================================================
# Linting with TFLint
# ============================================================================

# Lint runtime directory (recommended - fast and focused)
tflint: tflint-runtime

tflint-runtime:
	@echo "$(BLUE)Linting runtime Terraform files...$(NC)"
	@if command -v tflint >/dev/null 2>&1; then \
		cd runtime && tflint --init && tflint; \
		echo "$(GREEN)Runtime lint complete!$(NC)"; \
	else \
		echo "$(RED)tflint is not installed.$(NC)"; \
		echo "Install it from: https://github.com/terraform-linters/tflint"; \
		echo "  macOS: brew install tflint"; \
		exit 1; \
	fi

tflint-modules:
	@echo "$(BLUE)Linting Terraform modules...$(NC)"
	@if command -v tflint >/dev/null 2>&1; then \
		for dir in modules/*/; do \
			if [ -f "$$dir/main.tf" ]; then \
				echo "  Linting $$dir"; \
				cd "$$dir" && tflint --init && tflint; \
				cd - >/dev/null; \
			fi \
		done; \
		echo "$(GREEN)Module lint complete!$(NC)"; \
	else \
		echo "$(RED)tflint is not installed.$(NC)"; \
		echo "Install it from: https://github.com/terraform-linters/tflint"; \
		echo "  macOS: brew install tflint"; \
		exit 1; \
	fi

tflint-all: tflint-runtime tflint-modules
	@echo "$(GREEN)All linting complete!$(NC)"

# ============================================================================
# Security Scanning with Trivy
# ============================================================================

# Scan runtime directory (recommended - fast and focused)
trivy: trivy-runtime

trivy-runtime:
	@echo "$(BLUE)Scanning runtime infrastructure for security issues...$(NC)"
	@if command -v trivy >/dev/null 2>&1; then \
		trivy config runtime/ \
			--severity CRITICAL,HIGH,MEDIUM \
			--exit-code 0 \
			--format table; \
		echo ""; \
		echo "$(GREEN)Runtime security scan complete!$(NC)"; \
		echo "$(YELLOW)Tip: Run 'make trivy-all' for detailed scanning including modules$(NC)"; \
	else \
		echo "$(RED)trivy is not installed.$(NC)"; \
		echo "Install it from: https://aquasecurity.github.io/trivy/"; \
		echo "  macOS: brew install trivy"; \
		echo "  Linux: https://aquasecurity.github.io/trivy/latest/getting-started/installation/"; \
		exit 1; \
	fi

trivy-modules:
	@echo "$(BLUE)Scanning modules for security issues...$(NC)"
	@if command -v trivy >/dev/null 2>&1; then \
		for dir in modules/*/; do \
			if [ -f "$$dir/main.tf" ]; then \
				ignore_flag=""; \
				if [ -f "$$dir/.trivyignore" ]; then \
					ignore_flag="--ignorefile $$dir/.trivyignore"; \
				fi; \
				echo "  Scanning $$dir"; \
				trivy config "$$dir" \
					--severity CRITICAL,HIGH,MEDIUM \
					--exit-code 0 \
					--format table \
					$$ignore_flag; \
			fi \
		done; \
		echo ""; \
		echo "$(GREEN)Modules security scan complete!$(NC)"; \
	else \
		echo "$(RED)trivy is not installed.$(NC)"; \
		echo "Install it from: https://aquasecurity.github.io/trivy/"; \
		exit 1; \
	fi

trivy-all:
	@echo "$(BLUE)Running comprehensive security scan...$(NC)"
	@if command -v trivy >/dev/null 2>&1; then \
		echo ""; \
		echo "$(YELLOW)Scanning runtime infrastructure...$(NC)"; \
		trivy config runtime/ \
			--severity CRITICAL,HIGH,MEDIUM,LOW \
			--exit-code 0 \
			--format table \
			--ignorefile .trivyignore; \
		echo ""; \
		echo "$(YELLOW)Scanning modules...$(NC)"; \
		for dir in modules/*/; do \
			if [ -f "$$dir/main.tf" ]; then \
				ignore_flag=""; \
				if [ -f "$$dir/.trivyignore" ]; then \
					ignore_flag="--ignorefile $$dir/.trivyignore"; \
				fi; \
				echo "  Scanning $$dir"; \
				trivy config "$$dir" \
					--severity CRITICAL,HIGH,MEDIUM,LOW \
					--exit-code 0 \
					--format table \
					$$ignore_flag; \
			fi \
		done; \
		echo ""; \
		echo "$(GREEN)Comprehensive security scan complete!$(NC)"; \
	else \
		echo "$(RED)trivy is not installed.$(NC)"; \
		echo "Install it from: https://aquasecurity.github.io/trivy/"; \
		exit 1; \
	fi

# Trivy scan with CI/CD mode (fails on critical/high in runtime + modules)
trivy-ci:
	@echo "$(BLUE)Running Trivy scan in CI/CD mode...$(NC)"
	@if command -v trivy >/dev/null 2>&1; then \
		trivy config runtime/ modules/ \
			--severity CRITICAL,HIGH \
			--exit-code 1 \
			--format table \
			--ignorefile .trivyignore 2>/dev/null || true; \
	else \
		echo "$(RED)trivy is not installed.$(NC)"; \
		exit 1; \
	fi
	@echo "$(GREEN)Trivy CI scan complete!$(NC)"

# Run all CI lint targets (requires terraform, tflint, trivy in PATH)
lint-ci: fmt-check init-ci validate tflint trivy-ci

# ============================================================================
# Utility Commands
# ============================================================================

# Show current Terraform state for an environment
state-dev:
	@echo "$(BLUE)Showing Terraform state for dev...$(NC)"
	cd runtime && terraform state list

state-staging:
	@echo "$(BLUE)Showing Terraform state for staging...$(NC)"
	cd runtime && terraform state list

state-production:
	@echo "$(BLUE)Showing Terraform state for production...$(NC)"
	cd runtime && terraform state list

# Output values for an environment
output-dev:
	@echo "$(BLUE)Showing outputs for dev...$(NC)"
	cd runtime && terraform output

output-staging:
	@echo "$(BLUE)Showing outputs for staging...$(NC)"
	cd runtime && terraform output

output-production:
	@echo "$(BLUE)Showing outputs for production...$(NC)"
	cd runtime && terraform output
