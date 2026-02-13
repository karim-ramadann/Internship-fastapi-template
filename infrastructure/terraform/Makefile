.PHONY: help init-dev init-staging init-production plan-dev plan-staging plan-production apply-dev apply-staging apply-production destroy-dev destroy-staging destroy-production fmt validate docs docs-modules docs-runtime clean trivy trivy-runtime trivy-modules trivy-all

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
	@echo "  validate          - Validate runtime Terraform configuration"
	@echo "  docs              - Generate documentation for runtime and all modules"
	@echo "  docs-modules      - Generate documentation for modules only"
	@echo "  docs-runtime      - Generate documentation for runtime only"
	@echo "  clean             - Clean Terraform cache files from runtime"
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

# Validate configuration (runtime only)
validate:
	@echo "$(BLUE)Validating runtime Terraform configuration...$(NC)"
	cd runtime && terraform validate

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
		for dir in modules/aws_*/; do \
			if [ -f "$$dir/main.tf" ]; then \
				echo "  Generating docs for $$dir"; \
				terraform-docs --config modules/.terraform-docs.yml "$$dir"; \
			fi \
		done; \
		for dir in modules/database modules/security; do \
			if [ -d "$$dir" ] && [ -f "$$dir/main.tf" ]; then \
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
		trivy config modules/ \
			--severity CRITICAL,HIGH,MEDIUM \
			--exit-code 0 \
			--format table; \
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
		trivy config modules/ \
			--severity CRITICAL,HIGH,MEDIUM,LOW \
			--exit-code 0 \
			--format table \
			--ignorefile .trivyignore; \
		echo ""; \
		echo "$(GREEN)Comprehensive security scan complete!$(NC)"; \
	else \
		echo "$(RED)trivy is not installed.$(NC)"; \
		echo "Install it from: https://aquasecurity.github.io/trivy/"; \
		exit 1; \
	fi

# Trivy scan with CI/CD mode (fails on critical/high issues)
trivy-ci:
	@echo "$(BLUE)Running Trivy scan in CI/CD mode...$(NC)"
	@if command -v trivy >/dev/null 2>&1; then \
		trivy config runtime/ \
			--severity CRITICAL,HIGH \
			--exit-code 1 \
			--format table \
			--ignorefile .trivyignore; \
	else \
		echo "$(RED)trivy is not installed.$(NC)"; \
		exit 1; \
	fi

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
